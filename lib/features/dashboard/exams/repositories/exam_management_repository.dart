import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:realtime_client/realtime_client.dart';
import 'package:arabilogia/core/services/supabase_service_interface.dart';
import 'package:arabilogia/core/services/supabase_service_wrapper.dart';
import '../models/exam_model.dart';

class ExamManagementRepository {
  final SupabaseServiceInterface _supabaseService;

  ExamManagementRepository({SupabaseServiceInterface? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseServiceWrapper();

  Future<void> publishExam(Exam exam) async {
    final minifiedData = exam.toMinifiedJson();

    await _supabaseService.from('exams').upsert({
      'id': exam.id,
      'title': exam.title,
      'subject_id': exam.subjectId,
      'duration_minutes': exam.durationMinutes,
      'grade': exam.grade,
      'data': minifiedData,
    });
  }

  Future<void> upsertExam(Exam exam) async {
    final minifiedData = exam.toMinifiedJson();

    await _supabaseService.from('exams').upsert({
      'id': exam.id,
      'title': exam.title,
      'subject_id': exam.subjectId,
      'duration_minutes': exam.durationMinutes,
      'grade': exam.grade,
      'data': minifiedData,
    }, onConflict: 'id');
  }

  Future<void> unpublishExam(String examId) async {
    await _supabaseService.from('exams').delete().eq('id', examId);
  }

  Future<void> publishDraft(String examId) async {
    final row = await _supabaseService
        .from('exams')
        .select('data, title')
        .eq('id', examId)
        .maybeSingle();
    if (row == null) return;
    final examData = Map<String, dynamic>.from(
      row['data'] as Map<String, dynamic>,
    );
    examData['p'] = 1;
    await _supabaseService
        .from('exams')
        .update({'title': row['title'], 'data': examData})
        .eq('id', examId);
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
      } catch (e) {
        debugPrint('ExamManagementRepository error: $e');
      }
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

  /// Lightweight rows (no `data` blob) for a known set of exam ids, returned
  /// in the same order as [examIds] so a lecture can list its exams in the
  /// order the teacher arranged them.
  Future<List<Map<String, dynamic>>> getExamSummaries(
    List<String> examIds,
  ) async {
    if (examIds.isEmpty) return const [];
    try {
      final response = await _supabaseService
          .from('exams')
          .select('id, title, subject_id, grade')
          .inFilter('id', examIds);
      final byId = {for (final row in response) row['id'] as String: row};
      return [
        for (final id in examIds)
          if (byId.containsKey(id)) Map<String, dynamic>.from(byId[id]!),
      ];
    } catch (e) {
      debugPrint('ExamManagementRepository getExamSummaries error: $e');
      return const [];
    }
  }
}
