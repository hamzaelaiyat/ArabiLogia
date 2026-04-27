import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ScoreRepository {
  final _supabase = Supabase.instance.client;

  static const String _scoresCacheKey = 'exam_scores_cache';

  Stream<List<Map<String, dynamic>>> streamExamParticipants(
    String examId, {
    Duration interval = const Duration(seconds: 3),
  }) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    Timer? timer;
    bool isCancelled = false;

    Future<void> poll() async {
      if (isCancelled || controller.isClosed) return;
      try {
        final response = await _supabase
            .from('exam_results')
            .select('*, profiles(full_name, username, grade)')
            .eq('exam_id', examId)
            .eq('status', 'completed')
            .order('created_at', ascending: false);
        if (!isCancelled && !controller.isClosed) {
          controller.add(List<Map<String, dynamic>>.from(response));
        }
      } catch (e) {
        debugPrint('Poll error for exam $examId: $e');
      }
    }

    timer = Timer.periodic(interval, (_) => poll());
    poll();

    controller.onCancel = () {
      isCancelled = true;
      timer?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Stream<List<Map<String, dynamic>>> streamExamsManaged({
    Duration interval = const Duration(seconds: 3),
  }) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    Timer? timer;
    bool isCancelled = false;

    Future<void> poll() async {
      if (isCancelled || controller.isClosed) return;
      try {
        final response = await _supabase
            .from('exams')
            .select('id, title, subject_id, created_at')
            .order('created_at', ascending: false);
        if (!isCancelled && !controller.isClosed) {
          controller.add(List<Map<String, dynamic>>.from(response));
        }
      } catch (e) {
        debugPrint('Poll error for exams: $e');
      }
    }

    timer = Timer.periodic(interval, (_) => poll());
    poll();

    controller.onCancel = () {
      isCancelled = true;
      timer?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Future<void> submitScore({
    required String examId,
    required String subject,
    required double score,
    List<String> wrongAnswers = const [],
    bool isCompleted = true,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('submitScore: No user logged in, cannot submit');
      return;
    }

    debugPrint(
      'submitScore: Submitting score for exam $examId, user ${user.id}, score $score, completed $isCompleted',
    );

    await _updateLocalCache(examId, score);

    try {
      final data = {
        'user_id': user.id,
        'exam_id': examId,
        'subject': subject,
        'score': score,
        'wrong_answers': wrongAnswers.toList(),
        'status': isCompleted ? 'completed' : 'abandoned',
      };
      debugPrint('submitScore: Inserting data: $data');

      final result = await _supabase.from('exam_results').insert(data).select();
      debugPrint('submitScore: Success, result: $result');
    } catch (e) {
      debugPrint('Error submitting score to server: $e');
      try {
        final minimalData = {
          'user_id': user.id,
          'exam_id': examId,
          'score': score,
        };
        debugPrint('submitScore: Trying minimal insert: $minimalData');
        await _supabase.from('exam_results').insert(minimalData);
        debugPrint('submitScore: Minimal insert success');
      } catch (e2) {
        debugPrint('Error: $e2');
      }
    }
  }

  Future<void> _updateLocalCache(String examId, double score) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheJson = prefs.getString(_scoresCacheKey) ?? '{}';
    final Map<String, dynamic> cache = json.decode(cacheJson);

    final currentBest = cache[examId] as double? ?? 0.0;
    if (score > currentBest) {
      cache[examId] = score;
      await prefs.setString(_scoresCacheKey, json.encode(cache));
    }
  }

  Future<Map<String, double>> getLocalScores() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheJson = prefs.getString(_scoresCacheKey) ?? '{}';
    final Map<String, dynamic> cache = json.decode(cacheJson);
    return cache.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  Future<void> syncScoresWithSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    debugPrint('Starting score synchronization for user ${user.id}');

    try {
      // Fetch existing exams to filter out deleted ones
      final existingExams = await _supabase
          .from('exams')
          .select('id')
          .then(
            (res) =>
                (res as List<dynamic>).map((e) => e['id'] as String).toSet(),
          );

      final remoteData = await _supabase
          .from('exam_results')
          .select('exam_id, score, subject')
          .eq('user_id', user.id);

      final List<dynamic> results = remoteData;
      final Map<String, double> remoteBestScores = {};
      final Set<String> remoteExamIds = {};

      for (final res in results) {
        final id = res['exam_id'] as String;
        final score = (res['score'] as num).toDouble();
        remoteExamIds.add(id);
        if ((remoteBestScores[id] ?? 0.0) < score) {
          remoteBestScores[id] = score;
        }
      }

      final localScores = await getLocalScores();

      for (final entry in localScores.entries) {
        final examId = entry.key;
        final score = entry.value;

        // Only push if: exam still exists AND not in remote
        if (!existingExams.contains(examId)) {
          debugPrint('Skipping score for deleted exam: $examId');
          continue;
        }

        if (!remoteExamIds.contains(examId)) {
          debugPrint('Pushing local-only score to server: $examId ($score)');
          try {
            await _supabase.from('exam_results').insert({
              'user_id': user.id,
              'exam_id': examId,
              'score': score,
              'subject': 'unknown',
              'wrong_answers': [],
            });
          } catch (e) {
            debugPrint('Failed to push local score $examId: $e');
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final Map<String, double> finalCache = Map.from(localScores);

      remoteBestScores.forEach((id, score) {
        if ((finalCache[id] ?? 0.0) < score) {
          finalCache[id] = score;
        }
      });

      await prefs.setString(_scoresCacheKey, json.encode(finalCache));
      debugPrint('Score synchronization completed successfully');
    } catch (e) {
      debugPrint('Critical error during score sync: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({
    int? grade,
    String period = 'all',
  }) async {
    try {
      var query = _supabase.rpc(
        'get_leaderboard_by_period',
        params: {'period_filter': period},
      );

      if (grade != null && grade != 0) {
        query = query.eq('grade', grade);
      }

      final response = await query
          .order('total_score', ascending: false)
          .limit(100);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getUserStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('leaderboard')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        debugPrint('No leaderboard data found for user ${user.id}');
      }

      return response;
    } catch (e) {
      debugPrint('Error fetching user stats: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 3}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('exam_results')
          .select('subject, score, created_at, exam_id')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching recent activity: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getDetailedProfileStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};

    final basicStats = await getUserStats();

    final recentExamResponse = await _supabase
        .from('exam_results')
        .select('subject, score, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1);

    Map<String, dynamic>? lastExam;
    if (recentExamResponse.isNotEmpty) {
      lastExam = Map<String, dynamic>.from(recentExamResponse.first);
    }

    return {
      'exams_completed': basicStats?['exams_completed'] ?? 0,
      'avg_score': basicStats?['avg_score'] ?? 0.0,
      'total_score': basicStats?['total_score'] ?? 0,
      'rank': basicStats?['rank'] ?? 0,
      'last_exam': lastExam,
    };
  }

  Future<List<Map<String, dynamic>>> getExamsManaged() async {
    try {
      final response = await _supabase
          .from('exams')
          .select('id, title, subject_id, created_at')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching managed exams: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getExamParticipants(String examId) async {
    try {
      debugPrint('getExamParticipants: Fetching for examId: $examId');
      final response = await _supabase
          .from('exam_results')
          .select('*, profiles(full_name, username, grade)')
          .eq('exam_id', examId)
          .eq('status', 'completed')
          .order('created_at', ascending: false);
      debugPrint(
        'getExamParticipants: Got ${response.length} results: $response',
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching exam participants: $e');
      return [];
    }
  }

  int _mapUiGradeToDbGrade(int uiGrade) {
    if (uiGrade == 0) return 0;
    return uiGrade + 9;
  }

  Future<List<Map<String, dynamic>>> getGradeProfiles(int grade) async {
    try {
      var query = _supabase
          .from('profiles')
          .select('id, full_name, username, grade');

      final dbGrade = _mapUiGradeToDbGrade(grade);
      if (dbGrade != 0) {
        query = query.eq('grade', dbGrade);
      }

      final response = await query.order('full_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching grade profiles: $e');
      return [];
    }
  }
}
