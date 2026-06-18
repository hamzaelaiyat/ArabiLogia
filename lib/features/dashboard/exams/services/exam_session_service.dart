import 'package:arabilogia/data/local/database.dart';
import 'package:arabilogia/data/local/daos/session_dao.dart';
import 'package:arabilogia/data/local/models/exam_session_data.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_session.dart';

class ExamSessionService {
  final AppDatabase _database;
  late final SessionDao _dao;

  ExamSessionService({AppDatabase? database})
      : _database = database ?? AppDatabase() {
    _dao = SessionDao(_database);
  }

  ExamSessionData _toData(ExamSession session) {
    return ExamSessionData(
      examId: session.examId,
      examTitle: session.examTitle,
      durationMinutes: session.durationMinutes,
      startTimestamp: session.startTimestamp,
      selectedAnswers: session.selectedAnswers,
      expiresAt:
          session.startTimestamp + session.durationMinutes * 60 * 1000,
    );
  }

  ExamSession? _toSession(ExamSessionData? data) {
    if (data == null) return null;
    return ExamSession(
      examId: data.examId,
      examTitle: data.examTitle,
      durationMinutes: data.durationMinutes,
      startTimestamp: data.startTimestamp,
      selectedAnswers: data.selectedAnswers,
    );
  }

  Future<void> saveSession(ExamSession session) async {
    await _dao.saveSession(_toData(session));
  }

  Future<ExamSession?> getSession() async {
    try {
      final data = await _dao.getSession();
      if (data == null) return null;
      final session = _toSession(data);
      if (session == null) return null;
      if (session.isExpired) {
        await _dao.deleteSession();
        return null;
      }
      return session;
    } catch (_) {
      await _dao.deleteSession();
      return null;
    }
  }

  Future<void> updateAnswers(Map<int, String?> answers) async {
    final session = await getSession();
    if (session == null) return;
    final updated = session.copyWith(selectedAnswers: answers);
    await saveSession(updated);
  }

  Future<void> refreshStartTime() async {
    final session = await getSession();
    if (session == null) return;
    final updated = session.copyWith(
      startTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await saveSession(updated);
  }

  Future<void> clearSession() async {
    await _dao.deleteSession();
  }

  Future<bool> hasInProgressExam() async {
    final session = await getSession();
    return session != null;
  }

  String formatRemainingTime(int seconds) {
    if (seconds <= 0) return '00:00';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
