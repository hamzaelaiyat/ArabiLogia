import 'package:arabilogia/core/services/supabase_service_interface.dart';
import 'package:arabilogia/data/local/database.dart';
import 'student_exam_repository.dart';
import 'exam_management_repository.dart';
import 'exam_participants_repository.dart';
import '../models/exam_model.dart';

export 'student_exam_repository.dart';
export 'exam_management_repository.dart';
export 'exam_participants_repository.dart';

class ExamRepository {
  final StudentExamRepository _student;
  final ExamManagementRepository _management;
  final ExamParticipantsRepository _participants;

  ExamRepository({
    SupabaseServiceInterface? supabaseService,
    AppDatabase? database,
  }) : _student = StudentExamRepository(
          supabaseService: supabaseService,
          database: database,
        ),
       _management = ExamManagementRepository(supabaseService: supabaseService),
       _participants = ExamParticipantsRepository(
         supabaseService: supabaseService,
       );

  Future<List<Map<String, dynamic>>> getExamsBySubject(String subjectId) =>
      _student.getExamsBySubject(subjectId);

  Future<Exam?> loadExamById(String subjectId, String examId) =>
      _student.loadExamById(subjectId, examId);

  Future<void> publishExam(Exam exam) => _management.publishExam(exam);

  Future<void> upsertExam(Exam exam) => _management.upsertExam(exam);

  Future<void> unpublishExam(String examId) =>
      _management.unpublishExam(examId);

  Future<void> publishDraft(String examId) =>
      _management.publishDraft(examId);

  Stream<List<Map<String, dynamic>>> streamExamsManagedRealtime() =>
      _management.streamExamsManagedRealtime();

  Stream<List<Map<String, dynamic>>> streamExamsManaged({
    Duration interval = const Duration(seconds: 3),
  }) => _management.streamExamsManaged(interval: interval);

  Future<List<Map<String, dynamic>>> getExamsManaged() =>
      _management.getExamsManaged();

  Stream<List<Map<String, dynamic>>> streamExamParticipantsRealtime(
    String examId,
  ) => _participants.streamExamParticipantsRealtime(examId);

  Future<List<Map<String, dynamic>>> getExamParticipants(String examId) =>
      _participants.getExamParticipants(examId);

  Future<List<Map<String, dynamic>>> getGradeProfiles(int grade) =>
      _participants.getGradeProfiles(grade);
}
