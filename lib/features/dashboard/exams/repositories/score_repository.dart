import 'package:arabilogia/core/services/supabase_service_interface.dart';
import 'package:arabilogia/core/services/supabase_service_wrapper.dart';
import 'package:arabilogia/data/local/database.dart';
import 'package:arabilogia/data/local/daos/score_dao.dart';
import 'package:flutter/foundation.dart';

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
    int wrongMask = 0,
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
      } catch (e) {
        debugPrint('ScoreRepository error: $e');
      }
    }

    try {
      final data = {
        'user_id': user.id,
        'exam_id': examId,
        'subject': subject,
        'score': score,
        'points': points,
        'wrong_mask': wrongMask,
        'status': isCompleted ? 'completed' : 'abandoned',
      };
      await _supabaseService
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
                'wrong_mask': 0,
              });
              await _scoreDao.markSynced(entry.examId);
            } catch (e) {
              debugPrint('ScoreRepository error: $e');
            }
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
        debugPrint('ScoreRepository error: $e');
        if (attempt == maxRetries) {
          return;
        }
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }

  Future<void> recordExamPoints(int points) async {
    if (points <= 0) return;
    try {
      await _supabaseService.rpc('record_exam_points', params: {'p_points': points});
    } catch (e) {
      debugPrint('ScoreRepository recordExamPoints error: $e');
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
