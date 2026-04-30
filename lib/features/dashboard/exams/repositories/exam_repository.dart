import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam_model.dart';
import 'score_repository.dart';

class ExamRepository {
  final _supabase = Supabase.instance.client;

  Future<void> publishExam(Exam exam) async {
    final minifiedData = exam.toMinifiedJson();

    await _supabase.from('exams').upsert({
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

    await _supabase.from('exams').upsert({
      'id': exam.id,
      'title': exam.title,
      'subject_id': exam.subjectId,
      'duration_minutes': exam.durationMinutes,
      'grade': exam.grade,
      'data': minifiedData,
    }, onConflict: 'id');
  }

  Future<void> unpublishExam(String examId) async {
    await _supabase.from('exams').delete().eq('id', examId);
  }

  // Static registry of exam files by subject ID
  // NOTE: Default local exams have been removed - all exams must be published to Supabase
  static const Map<String, List<String>> _registry = {};

  Future<List<Map<String, dynamic>>> getExamsBySubject(String subjectId) async {
    final List<Map<String, dynamic>> exams = [];
    final scoreRepo = ScoreRepository();
    final localScores = await scoreRepo.getLocalScores();
    final prefs = await SharedPreferences.getInstance();
    final autoDownload = prefs.getBool('auto_download_exams') ?? true;

    // Get student grade from metadata (10, 11, 12) and map to exam grade (1, 2, 3)
    final user = _supabase.auth.currentUser;
    final studentGradeRaw = user?.userMetadata?['grade'] as int? ?? 10;
    final examGrade = studentGradeRaw - 9; // 10→1, 11→2, 12→3

    // 1. Load Remote Exams from Supabase (filtered by grade)
    final Set<String> remoteExamIds = {};
    try {
      final remoteData = await _supabase
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

        // Cache if auto-download is enabled
        if (autoDownload) {
          await prefs.setString(
            'offline_exam_${exam.id}',
            json.encode(examData),
          );
        }

        exams.add(_processExam(exam, localScores, isRemote: true));
      }
    } catch (e) {
      print('Error fetching remote exams: $e');
      // If offline, load from cache
      final keys = prefs.getKeys().where((k) => k.startsWith('offline_exam_'));
      for (final key in keys) {
        final cachedJson = prefs.getString(key);
        if (cachedJson != null) {
          final data = json.decode(cachedJson);
          final exam = Exam.fromMinifiedJson(data);
          // Only show published exams matching student's grade
          if (!exam.isPublished) continue;
          if (exam.subjectId == subjectId && exam.grade == examGrade) {
            remoteExamIds.add(exam.id);
            exams.add(_processExam(exam, localScores, isRemote: true));
          }
        }
      }
    }

    // 2. No local exams - all must come from Supabase
    // (Default local exams were removed)

    // Sort: Published exams first, then by title
    exams.sort((a, b) {
      if (a['isRemote'] != b['isRemote']) {
        return a['isRemote'] ? -1 : 1;
      }
      return (a['title'] as String).compareTo(b['title'] as String);
    });

    // 3. Handle locking logic.
    bool previousExamPassed = true;
    for (int i = 0; i < exams.length; i++) {
      final exam = exams[i];
      exams[i]['locked'] = !previousExamPassed;
      final score = exam['score'] as int;
      previousExamPassed = (score >= 60);
    }

    return exams;
  }

  Map<String, dynamic> _processExam(
    Exam exam,
    Map<String, double> localScores, {
    String? path,
    bool isRemote = false,
  }) {
    final userScore = localScores[exam.id];
    return {
      'id': exam.id,
      'title': exam.title,
      'questions': exam.questions.length,
      'duration': exam.durationMinutes,
      'path': path,
      'locked': false, // Will be set in getExamsBySubject
      'completed': userScore != null,
      'score': userScore?.toInt() ?? 0,
      'isRemote': isRemote,
    };
  }

  Future<Exam?> loadExamById(String subjectId, String examId) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Check Offline Cache
    final cached = prefs.getString('offline_exam_$examId');
    if (cached != null) {
      return Exam.fromMinifiedJson(json.decode(cached));
    }

    // 2. No local registry - all exams must come from Supabase
    // (Static registry of default local exams was removed)

    // 3. Try Remote
    try {
      final data = await _supabase
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

  Future<Exam> loadExam(String path) async {
    final String jsonString = await rootBundle.loadString(path);
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return Exam.fromJson(jsonMap);
  }
}
