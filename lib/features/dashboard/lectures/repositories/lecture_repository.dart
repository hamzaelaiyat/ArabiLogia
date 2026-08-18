import 'dart:async';
import 'package:realtime_client/realtime_client.dart';
import 'package:arabilogia/core/services/supabase_service_interface.dart';
import 'package:arabilogia/core/services/supabase_service_wrapper.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';
import '../models/lecture.dart';

class LectureRepository {
  final SupabaseServiceInterface _supabaseService;

  LectureRepository({SupabaseServiceInterface? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseServiceWrapper();

  Future<List<Map<String, dynamic>>> getLecturesByCategory(
    String categoryId,
  ) async {
    try {
      // Grade filtering is enforced server-side by the
      // "Students view published lectures for their grade" RLS policy
      // (uses lectures.grade_ids).
      final response = await _supabaseService
          .from('lectures')
          .select()
          .eq('course_id', categoryId)
          .eq('is_published', true)
          .order('sort_order');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLecturesManaged() async {
    try {
      final response = await _supabaseService
          .from('lectures')
          .select()
          .order('created_at', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> streamLecturesManagedRealtime() {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    Future<void> fetchLectures() async {
      if (controller.isClosed) return;
      try {
        final response = await _supabaseService
            .from('lectures')
            .select()
            .order('created_at', ascending: false);
        if (!controller.isClosed) {
          controller.add(List<Map<String, dynamic>>.from(response));
        }
      } catch (e) {
        // Log or handle error
      }
    }

    fetchLectures();

    final channel = _supabaseService.realtimeClient.channel('lectures-managed');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'lectures',
          callback: (_) => fetchLectures(),
        )
        .subscribe();

    controller.onCancel = () async {
      await channel.unsubscribe();
      await controller.close();
    };

    return controller.stream;
  }

  Future<Lecture?> getLectureById(String id) async {
    try {
      final response = await _supabaseService
          .from('lectures')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Lecture.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> upsertLecture(Lecture lecture) async {
    await _supabaseService.from('lectures').upsert(
      lecture.toJson(),
      onConflict: 'id',
    );
  }

  Future<void> deleteLecture(String id) async {
    await _supabaseService.from('lectures').delete().eq('id', id);
  }

  Future<void> togglePublishStatus(String lectureId, bool newStatus) async {
    await _supabaseService
        .from('lectures')
        .update({'is_published': newStatus})
        .eq('id', lectureId);

    final lecture = await getLectureById(lectureId);
    if (lecture != null) {
      final examRepo = ExamRepository();
      for (final block in lecture.contentBlocks) {
        if (block.type == BlockType.quiz || block.type == BlockType.exam) {
          if (block.content.isNotEmpty) {
            final exam = await examRepo.loadExamById(lecture.courseId, block.content);
            if (exam != null) {
              await examRepo.upsertExam(exam.copyWith(isPublished: newStatus));
            }
          }
        }
      }
      for (final examId in lecture.examIds) {
        final exam = await examRepo.loadExamById(lecture.courseId, examId);
        if (exam != null) {
          await examRepo.upsertExam(exam.copyWith(isPublished: newStatus));
        }
      }
    }
  }
}
