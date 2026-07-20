import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabilogia/core/services/supabase_service_interface.dart';
import 'package:arabilogia/core/services/supabase_service_wrapper.dart';
import 'package:arabilogia/data/local/database.dart';
import '../models/exam_model.dart';
import '../utils/grade_mapper.dart';
import 'score_repository.dart';

class StudentExamRepository {
  final SupabaseServiceInterface _supabaseService;
  final AppDatabase _database;

  StudentExamRepository({
    SupabaseServiceInterface? supabaseService,
    AppDatabase? database,
  }) : _supabaseService = supabaseService ?? SupabaseServiceWrapper(),
       _database = database ?? AppDatabase.instance;

  Future<List<Map<String, dynamic>>> getExamsBySubject(String subjectId) async {
    final List<Map<String, dynamic>> exams = [];
    final scoreRepo = ScoreRepository(database: _database);
    final localScores = await scoreRepo.getLocalScores();
    final prefs = await SharedPreferences.getInstance();
    final autoDownload = prefs.getBool('auto_download_exams') ?? true;

    final user = _supabaseService.auth.currentUser;
    final studentGradeRaw = user?.userMetadata?['grade'] as int? ?? 10;
    final examGrade = mapStudentGradeToExamGrade(studentGradeRaw);

    final Set<String> remoteExamIds = {};
    try {
      final remoteData = await _supabaseService
          .from('exams')
          .select()
          .eq('subject_id', subjectId)
          .eq('grade', examGrade);

      for (final data in remoteData) {
        final examData = data['data'] as Map<String, dynamic>;
        final exam = Exam.fromMinifiedJson(examData);

        if (!exam.isPublished) continue;

        remoteExamIds.add(exam.id);

        if (autoDownload) {
          await _database.examDao.cacheExamFields(
            id: exam.id,
            title: exam.title,
            subjectId: subjectId,
            grade: examGrade,
            data: json.encode(examData),
          );
        }

        exams.add(_processExam(exam, localScores, isRemote: true));
      }
    } catch (e) {
      final cachedExams = await _database.examDao.getCachedExamsBySubject(
        subjectId,
        examGrade,
      );

      for (final cached in cachedExams) {
        final data = json.decode(cached.data) as Map<String, dynamic>;
        final exam = Exam.fromMinifiedJson(data);
        if (!exam.isPublished) continue;
        remoteExamIds.add(exam.id);
        exams.add(_processExam(exam, localScores, isRemote: true));
      }
    }

    exams.sort(
      (a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int),
    );

    bool previousExamPassed = true;
    int previousPassThreshold = 85;
    for (final exam in exams) {
      exam['locked'] = !previousExamPassed;
      final score = exam['score'] as int;
      previousExamPassed = (score >= previousPassThreshold);
      previousPassThreshold = exam['pass_threshold'] as int;
    }

    return exams;
  }

  Map<String, dynamic> _processExam(
    Exam exam,
    Map<String, dynamic> localScores, {
    String? path,
    bool isRemote = false,
  }) {
    final userScoreEntry = localScores[exam.id];
    final userScore = userScoreEntry is Map
        ? (userScoreEntry['score'] as num?)?.toDouble()
        : (userScoreEntry as num?)?.toDouble();
    return {
      'id': exam.id,
      'title': exam.title,
      'questions': exam.questions.length,
      'duration': exam.durationMinutes ?? 30,
      'path': path,
      'locked': false,
      'completed': userScore != null,
      'score': userScore?.toInt() ?? 0,
      'isRemote': isRemote,
      'sort_order': exam.sortOrder,
      'level': exam.level,
      'pass_threshold': exam.passPercentage,
    };
  }

  Future<Exam?> loadExamById(String subjectId, String examId) async {
    final cached = await _database.examDao.getCachedExam(examId);
    if (cached != null) {
      return Exam.fromMinifiedJson(json.decode(cached.data));
    }

    try {
      final data = await _supabaseService
          .from('exams')
          .select('data')
          .eq('id', examId)
          .maybeSingle();
      if (data != null) {
        final examData = data['data'] as Map<String, dynamic>;
        return Exam.fromMinifiedJson(examData);
      }
    } catch (e) {
      print('Error loading remote exam $examId: $e');
    }

    return null;
  }
}
