import 'dart:async';
import 'package:realtime_client/realtime_client.dart';
import 'package:arabilogia/core/services/supabase_service_interface.dart';
import 'package:arabilogia/core/services/supabase_service_wrapper.dart';
import 'package:arabilogia/data/local/database.dart';
import 'package:arabilogia/data/local/daos/score_dao.dart';
import 'package:arabilogia/features/dashboard/exams/utils/grade_mapper.dart';

class ScoreRepository {
  static final ScoreRepository _instance = ScoreRepository._internal();
  factory ScoreRepository({
    SupabaseServiceInterface? supabaseService,
    AppDatabase? database,
  }) => supabaseService != null || database != null
      ? ScoreRepository._create(
          supabaseService: supabaseService ?? SupabaseServiceWrapper(),
          database: database ?? AppDatabase.instance,
        )
      : _instance;
  ScoreRepository._internal()
    : _supabaseService = SupabaseServiceWrapper(),
      _scoreDao = ScoreDao(AppDatabase.instance);
  ScoreRepository._create({
    required SupabaseServiceInterface supabaseService,
    required AppDatabase database,
  }) : _supabaseService = supabaseService,
       _scoreDao = ScoreDao(database);

  final SupabaseServiceInterface _supabaseService;
  final ScoreDao _scoreDao;
  Future<void>? _syncFuture;

  Future<bool> submitScore({
    required String examId,
    required String subject,
    required double score,
    List<String> wrongAnswers = const [],
    bool isCompleted = true,
    int points = 0,
  }) async {
    final user = _supabaseService.auth.currentUser;
    if (user == null) {
      return false;
    }

    await _scoreDao.upsertScore(examId, score, points);

    if (isCompleted) {
      try {
        final existing = await _supabaseService
            .from('exam_results')
            .select('id')
            .eq('user_id', user.id)
            .eq('exam_id', examId)
            .eq('status', 'completed')
            .maybeSingle();
        if (existing != null) {
          return true;
        }
      } catch (_) {}
    }

    try {
      final data = {
        'user_id': user.id,
        'exam_id': examId,
        'subject': subject,
        'score': score,
        'points': points,
        'wrong_answers': wrongAnswers.toList(),
        'status': isCompleted ? 'completed' : 'abandoned',
      };
      final result = await _supabaseService
          .from('exam_results')
          .insert(data)
          .select();
      return true;
    } catch (e) {
      try {
        final minimalData = {
          'user_id': user.id,
          'exam_id': examId,
          'score': score,
          'points': points,
        };
        await _supabaseService.from('exam_results').insert(minimalData);
        return true;
      } catch (e2) {
        return false;
      }
    }
  }

  Future<Map<String, dynamic>> getLocalScores() async {
    return _scoreDao.getAllScores();
  }

  Future<void> syncScoresWithSupabase() async {
    if (_syncFuture != null) {
      await _syncFuture;
      return;
    }

    _syncFuture = _performSync();
    await _syncFuture;
    _syncFuture = null;
  }

  Future<void> _performSync() async {
    final user = _supabaseService.auth.currentUser;
    if (user == null) return;

    const maxRetries = 3;
    var delay = const Duration(seconds: 1);

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final existingExams = await _supabaseService
            .from('exams')
            .select('id')
            .then(
              (res) =>
                  (res as List<dynamic>).map((e) => e['id'] as String).toSet(),
            );

        final remoteData = await _supabaseService
            .from('exam_results')
            .select('exam_id, score, points, subject')
            .eq('user_id', user.id);

        final List<dynamic> results = remoteData;
        final Map<String, Map<String, dynamic>> remoteBestScores = {};
        final Set<String> remoteExamIds = {};

        for (final res in results) {
          final id = res['exam_id'] as String;
          final score = (res['score'] as num).toDouble();
          final points = (res['points'] as int?) ?? 0;
          remoteExamIds.add(id);
          final existing = remoteBestScores[id];
          if (existing == null || (existing['score'] as double) < score) {
            remoteBestScores[id] = {'score': score, 'points': points};
          }
        }

        final unsynced = await _scoreDao.getUnsyncedScores();

        for (final entry in unsynced) {
          if (!existingExams.contains(entry.examId)) {
            continue;
          }

          if (!remoteExamIds.contains(entry.examId)) {
            try {
              await _supabaseService.from('exam_results').insert({
                'user_id': user.id,
                'exam_id': entry.examId,
                'score': entry.score,
                'points': entry.points,
                'subject': 'unknown',
                'wrong_answers': [],
              });
              await _scoreDao.markSynced(entry.examId);
            } catch (e) {}
          }
        }

        for (final entry in remoteBestScores.entries) {
          await _scoreDao.upsertScore(
            entry.key,
            (entry.value['score'] as num).toDouble(),
            (entry.value['points'] as int?) ?? 0,
          );
        }

        return;
      } catch (e) {
        if (attempt == maxRetries) {
          return;
        }
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({
    int? grade,
    String period = 'all',
  }) async {
    try {
      var query = _supabaseService.rpc(
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
      return [];
    }
  }

  Future<Map<String, dynamic>?> getUserStats() async {
    final user = _supabaseService.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabaseService
          .rpc('get_leaderboard_by_period', params: {'period_filter': 'all'})
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {}

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 3}) async {
    final user = _supabaseService.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabaseService
          .from('exam_results')
          .select('subject, score, created_at, exam_id')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getDetailedProfileStats() async {
    final user = _supabaseService.auth.currentUser;
    if (user == null) return {};

    final basicStats = await getUserStats();

    final recentExamResponse = await _supabaseService
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

  Stream<List<Map<String, dynamic>>> streamExamsManagedRealtime() {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    Future<void> fetchExams() async {
      if (controller.isClosed) return;
      try {
        final response = await _supabaseService
            .from('exams')
            .select('id, title, subject_id, grade, created_at, data')
            .order('created_at', ascending: false);
        if (!controller.isClosed) {
          controller.add(List<Map<String, dynamic>>.from(response));
        }
      } catch (e) {}
    }

    fetchExams();

    final channel = _supabaseService.realtimeClient.channel('exams-managed');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'exams',
          callback: (_) => fetchExams(),
        )
        .subscribe();

    controller.onCancel = () async {
      await channel.unsubscribe();
      await controller.close();
    };

    return controller.stream;
  }

  Stream<List<Map<String, dynamic>>> streamExamsManaged({
    Duration interval = const Duration(seconds: 3),
  }) {
    return streamExamsManagedRealtime();
  }

  Future<List<Map<String, dynamic>>> getExamsManaged() async {
    try {
      final response = await _supabaseService
          .from('exams')
          .select('id, title, subject_id, grade, created_at, data')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> streamExamParticipantsRealtime(
    String examId,
  ) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    Future<void> fetchAndAdd() async {
      if (controller.isClosed) return;
      try {
        final response = await _supabaseService
            .from('exam_results')
            .select('*')
            .eq('exam_id', examId)
            .eq('status', 'completed')
            .order('created_at', ascending: false);
        if (!controller.isClosed) {
          final results = List<Map<String, dynamic>>.from(response);
          if (results.isNotEmpty) {
            final allProfiles = await _supabaseService
                .from('profiles')
                .select('id, full_name, username, grade');
            final profileMap = {
              for (var p in allProfiles) p['id'] as String: p,
            };
            for (var row in results) {
              row['profile'] = profileMap[row['user_id'] as String];
            }
          }
          controller.add(results);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.add([]);
        }
      }
    }

    final channel = _supabaseService.realtimeClient.channel(
      'exam-participants-$examId',
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'exam_results',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'exam_id',
        value: examId,
      ),
      callback: (payload) {
        fetchAndAdd();
      },
    );
    channel.subscribe();

    fetchAndAdd();

    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };

    return controller.stream;
  }

  Future<List<Map<String, dynamic>>> getExamParticipants(String examId) async {
    try {
      final response = await _supabaseService
          .from('exam_results')
          .select('*')
          .eq('exam_id', examId)
          .eq('status', 'completed')
          .order('created_at', ascending: false);
      final results = List<Map<String, dynamic>>.from(response);
      if (results.isNotEmpty) {
        final allProfiles = await _supabaseService
            .from('profiles')
            .select('id, full_name, username, grade');
        final profileMap = {for (var p in allProfiles) p['id'] as String: p};
        for (var row in results) {
          row['profile'] = profileMap[row['user_id'] as String];
        }
      }
      final seen = <String>{};
      final deduplicated = <Map<String, dynamic>>[];
      for (final row in results) {
        final uid = row['user_id'] as String;
        if (seen.add(uid)) {
          deduplicated.add(Map<String, dynamic>.from(row));
        }
      }
      return deduplicated;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getGradeProfiles(int grade) async {
    try {
      final dbGrade = mapUiGradeToDbGrade(grade);
      var query = _supabaseService
          .from('profiles')
          .select('id, full_name, username, grade');

      if (dbGrade != 0) {
        query = query.eq('grade', dbGrade);
      }

      final response = await query.order('full_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}
