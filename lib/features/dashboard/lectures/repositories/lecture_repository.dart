import 'package:arabilogia/core/services/supabase_service_interface.dart';
import 'package:arabilogia/core/services/supabase_service_wrapper.dart';
import 'package:arabilogia/features/dashboard/exams/utils/grade_mapper.dart';
import '../models/lecture.dart';

class LectureRepository {
  final SupabaseServiceInterface _supabaseService;

  LectureRepository({SupabaseServiceInterface? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseServiceWrapper();

  Future<List<Map<String, dynamic>>> getLecturesByCategory(
    String categoryId,
  ) async {
    final user = _supabaseService.auth.currentUser;
    final studentGradeRaw = user?.userMetadata?['grade'] as int? ?? 10;
    final examGrade = mapStudentGradeToExamGrade(studentGradeRaw);

    try {
      final response = await _supabaseService
          .from('lectures')
          .select()
          .eq('course_id', categoryId)
          .eq('grade', examGrade)
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
}
