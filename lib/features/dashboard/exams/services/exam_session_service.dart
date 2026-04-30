import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_session.dart';

class ExamSessionService {
  static const _sessionKey = 'in_progress_exam_session';
  static final ExamSessionService _instance = ExamSessionService._internal();

  factory ExamSessionService() => _instance;

  ExamSessionService._internal();

  /// Save exam session when starting or during exam
  Future<void> saveSession(ExamSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(session.toJson());
    await prefs.setString(_sessionKey, jsonStr);
  }

  /// Get saved exam session (if any)
  Future<ExamSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_sessionKey);
    if (jsonStr == null) return null;

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final session = ExamSession.fromJson(json);

      // Check if expired - if so, clear and return null
      if (session.isExpired) {
        await clearSession();
        return null;
      }

      return session;
    } catch (e) {
      // Invalid data, clear it
      await clearSession();
      return null;
    }
  }

  /// Update selected answers during exam
  Future<void> updateAnswers(Map<int, String?> answers) async {
    final current = await getSession();
    if (current == null) return;

    final updated = current.copyWith(selectedAnswers: answers);
    await saveSession(updated);
  }

  /// Update start timestamp (refresh on resume)
  Future<void> refreshStartTime() async {
    final current = await getSession();
    if (current == null) return;

    final updated = current.copyWith(
      startTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await saveSession(updated);
  }

  /// Clear saved session (exam completed or abandoned)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  /// Check if there's an in-progress exam
  Future<bool> hasInProgressExam() async {
    final session = await getSession();
    return session != null;
  }

  /// Get remaining time formatted (e.g., "15:30" for 15 min 30 sec)
  String formatRemainingTime(int seconds) {
    if (seconds <= 0) return '00:00';

    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
