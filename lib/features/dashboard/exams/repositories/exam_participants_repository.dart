import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:realtime_client/realtime_client.dart';
import 'package:arabilogia/core/services/supabase_service_interface.dart';
import 'package:arabilogia/core/services/supabase_service_wrapper.dart';
import 'package:arabilogia/core/models/grade_metadata.dart';

/// Roll-up of the completed attempts for a single exam, used by the teacher
/// dashboard to show a stat line without loading every student's row.
class ExamResultAggregate {
  final int participants;
  final double? averageScore;
  final double? bestScore;

  const ExamResultAggregate({
    this.participants = 0,
    this.averageScore,
    this.bestScore,
  });

  static const ExamResultAggregate empty = ExamResultAggregate();
}

class ExamParticipantsRepository {
  final SupabaseServiceInterface _supabaseService;

  ExamParticipantsRepository({SupabaseServiceInterface? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseServiceWrapper();

  /// One query for every exam in [examIds] instead of N per-exam queries.
  /// Returns a map keyed by exam id; exams with no attempts are absent.
  Future<Map<String, ExamResultAggregate>> getAggregatesForExams(
    List<String> examIds,
  ) async {
    if (examIds.isEmpty) return const {};
    try {
      final response = await _supabaseService
          .from('exam_results')
          .select('exam_id, score')
          .inFilter('exam_id', examIds)
          .eq('status', 'completed');

      final scoresByExam = <String, List<double>>{};
      for (final row in response) {
        final examId = row['exam_id'] as String?;
        final score = (row['score'] as num?)?.toDouble();
        if (examId == null || score == null) continue;
        (scoresByExam[examId] ??= []).add(score);
      }

      return {
        for (final entry in scoresByExam.entries)
          entry.key: ExamResultAggregate(
            participants: entry.value.length,
            averageScore:
                entry.value.reduce((a, b) => a + b) / entry.value.length,
            bestScore: entry.value.reduce((a, b) => a > b ? a : b),
          ),
      };
    } catch (e) {
      debugPrint('ExamParticipantsRepository getAggregatesForExams error: $e');
      return const {};
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
                .select('id, full_name, username, grade, role');
            final profileMap = {
              for (var p in allProfiles) p['id'] as String: p,
            };
            for (var row in results) {
              row['profile'] = profileMap[row['user_id'] as String];
            }
          }
          results.removeWhere((r) => r['profile'] == null);
          controller.add(results);
        }
      } catch (e) {
        debugPrint('ExamParticipantsRepository error: $e');
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
            .select('id, full_name, username, grade, role');
        final profileMap = {for (var p in allProfiles) p['id'] as String: p};
        for (var row in results) {
          row['profile'] = profileMap[row['user_id'] as String];
        }
      }
      final seen = <String>{};
      final deduplicated = <Map<String, dynamic>>[];
      for (final row in results) {
        if (row['profile'] == null) continue;
        final uid = row['user_id'] as String;
        if (seen.add(uid)) {
          deduplicated.add(Map<String, dynamic>.from(row));
        }
      }
      return deduplicated;
    } catch (e) {
      debugPrint('ExamParticipantsRepository error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getGradeProfiles(int grade) async {
    try {
      final dbGrade = grade;
      var query = _supabaseService
          .from('profiles')
          .select('id, full_name, username, grade');

      if (dbGrade != GradeMetadata.allGrades) {
        query = query.eq('grade', dbGrade);
      }

      final response = await query.order('full_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('ExamParticipantsRepository error: $e');
      return [];
    }
  }
}
