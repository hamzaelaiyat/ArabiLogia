import 'dart:convert';
import 'package:arabilogia/core/services/supabase_service_interface.dart';
import 'package:arabilogia/core/services/supabase_service_wrapper.dart';
import 'package:arabilogia/data/local/database.dart';
import 'package:arabilogia/data/local/daos/score_dao.dart';
import 'package:flutter/foundation.dart';

class ExamStartInfo {
  final String sessionId;
  final DateTime startedAt;
  final int durationSeconds;
  const ExamStartInfo({
    required this.sessionId,
    required this.startedAt,
    required this.durationSeconds,
  });
}

class ExamGradingResult {
  final String examId;
  final double score;
  final int correctCount;
  final int totalCount;
  final int wrongMask;
  final double accuracy;
  final double speedBonus;
  final int points;
  final String status;
  const ExamGradingResult({
    required this.examId,
    required this.score,
    required this.correctCount,
    required this.totalCount,
    required this.wrongMask,
    required this.accuracy,
    required this.speedBonus,
    required this.points,
    required this.status,
  });
}

class ExamReview {
  final Map<String, dynamic> data;
  final Map<String, dynamic> answers;
  const ExamReview({required this.data, required this.answers});
}

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

  /// Issues a server-side exam session. The returned session id is later
  /// passed to [submitExamAnswer] so the server can compute an accurate
  /// speed bonus from its own clock.
  Future<ExamStartInfo?> startExam(String examId) async {
    final user = _supabaseService.auth.currentUser;
    if (user == null) return null;
    try {
      final res = await _supabaseService.rpc(
        'start_exam',
        params: {'p_exam_id': examId},
      );
      if (res is! Map) return null;
      return ExamStartInfo(
        sessionId: res['session_id'] as String,
        startedAt: DateTime.parse(res['started_at'] as String),
        durationSeconds: res['duration_seconds'] as int,
      );
    } catch (e) {
      debugPrint('ScoreRepository.startExam error: $e');
      return null;
    }
  }

  /// Server-side grading. `answers` is keyed by question index with
  /// option ids ("o0", "o1", ...). Returns null on auth/transport
  /// failure (the screen treats that as "could not submit").
  Future<ExamGradingResult?> submitExamAnswer({
    required String examId,
    required Map<int, String?> answers,
    String? sessionId,
  }) async {
    final user = _supabaseService.auth.currentUser;
    if (user == null) return null;

    final encoded = jsonEncode(
      answers.map((k, v) => MapEntry(k.toString(), v)),
    );
    final params = <String, dynamic>{
      'p_exam_id': examId,
      'p_answers': encoded,
    };
    if (sessionId != null) params['p_session_id'] = sessionId;

    try {
      final res = await _supabaseService.rpc(
        'submit_exam_answer',
        params: params,
      );
      if (res is! Map) return null;
      final result = ExamGradingResult(
        examId: res['exam_id'] as String,
        score: (res['score'] as num).toDouble(),
        correctCount: res['correct_count'] as int,
        totalCount: res['total_count'] as int,
        wrongMask: (res['wrong_mask'] as num).toInt(),
        accuracy: (res['accuracy'] as num).toDouble(),
        speedBonus: (res['speed_bonus'] as num).toDouble(),
        points: res['points'] as int,
        status: res['status'] as String,
      );
      // Local cache best-effort: a sqflite failure must not block the
      // server-graded submission from reaching the caller.
      try {
        await _scoreDao.upsertScore(examId, result.score, result.points);
      } catch (e) {
        debugPrint('ScoreRepository local upsert ignored: $e');
      }
      return result;
    } catch (e) {
      debugPrint('ScoreRepository.submitExamAnswer error: $e');
      return null;
    }
  }

  /// Returns the exam data + answer key for review. Only available
  /// after the user has completed the exam.
  Future<ExamReview?> getExamReview(String examId) async {
    final user = _supabaseService.auth.currentUser;
    if (user == null) return null;
    try {
      final res = await _supabaseService.rpc(
        'get_exam_review',
        params: {'p_exam_id': examId},
      );
      if (res is! Map) return null;
      return ExamReview(
        data: Map<String, dynamic>.from(res['data'] as Map),
        answers: Map<String, dynamic>.from(res['answers'] as Map),
      );
    } catch (e) {
      debugPrint('ScoreRepository.getExamReview error: $e');
      return null;
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
        final remoteData = await _supabaseService
            .rpc('get_all_user_results', params: {'p_user_id': user.id});

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

        // Local-only scores from before server-side grading don't have
        // the answers needed to replay them. Clear the unsynced flag so
        // the loop stops retrying; the remote results (if any) already
        // won via the upsert below.
        for (final entry in unsynced) {
          await _scoreDao.markSynced(entry.examId);
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
        debugPrint('ScoreRepository error: $e');
        if (attempt == maxRetries) {
          return;
        }
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 3}) async {
    final user = _supabaseService.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabaseService
          .rpc('get_all_user_results', params: {'p_user_id': user.id})
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}
