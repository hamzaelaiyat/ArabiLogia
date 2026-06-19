import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabilogia/core/services/supabase_service_interface.dart';
import 'package:arabilogia/core/services/supabase_service_wrapper.dart';
import 'package:arabilogia/data/local/database.dart';
import 'package:arabilogia/data/local/daos/exam_dao.dart';
import '../models/exam_model.dart';
import '../utils/grade_mapper.dart';
import 'score_repository.dart';

class ExamRepository {
  final SupabaseServiceInterface _supabaseService;
  final AppDatabase _database;

  ExamRepository({
    SupabaseServiceInterface? supabaseService,
    AppDatabase? database,
  }) : _supabaseService = supabaseService ?? SupabaseServiceWrapper(),
       _database = database ?? AppDatabase.instance;

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

  Future<List<Map<String, dynamic>>> getExamsBySubject(String subjectId) async {
    final List<Map<String, dynamic>> exams = [];
    final scoreRepo = ScoreRepository(database: _database);
    final localScores = await scoreRepo.getLocalScores();
    final prefs = await SharedPreferences.getInstance();
    final autoDownload = prefs.getBool('auto_download_exams') ?? true;

    // Get student grade from metadata (10, 11, 12) and map to exam grade (1, 2, 3)
    final user = _supabaseService.auth.currentUser;
    final studentGradeRaw = user?.userMetadata?['grade'] as int? ?? 10;
    final examGrade = mapStudentGradeToExamGrade(studentGradeRaw);

    // 1. Load Remote Exams from Supabase (filtered by grade)
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

        // Only show published exams to students
        if (!exam.isPublished) continue;

        remoteExamIds.add(exam.id);

        // Cache in drift if auto-download is enabled
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
      // If offline, load from drift cache
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

    // 2. All exams come from Supabase (cached locally in drift)

    // Sort by sort_order so the lock chain follows the intended sequence
    // regardless of array index or insertion order.
    exams.sort(
      (a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int),
    );

    // 3. Handle locking logic (sequentially by sort_order).
    bool previousExamPassed = true;
    for (final exam in exams) {
      exam['locked'] = !previousExamPassed;
      final score = exam['score'] as int;
      previousExamPassed = (score >= 60);
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
      'locked': false, // Will be set in getExamsBySubject
      'completed': userScore != null,
      'score': userScore?.toInt() ?? 0,
      'isRemote': isRemote,
      'sort_order': exam.sortOrder,
    };
  }

  Future<Exam?> loadExamById(String subjectId, String examId) async {
    // 1. Check Drift Cache
    final cached = await _database.examDao.getCachedExam(examId);
    if (cached != null) {
      return Exam.fromMinifiedJson(json.decode(cached.data));
    }

    // 2. Try Remote
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
