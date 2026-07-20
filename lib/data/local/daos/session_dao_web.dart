import '../models/exam_session_data.dart';

class SessionDao {
  ExamSessionData? _session;

  SessionDao([dynamic _]);

  Future<void> saveSession(ExamSessionData session) async {
    _session = session;
  }

  Future<ExamSessionData?> getSession() async {
    return _session;
  }

  Future<void> deleteSession() async {
    _session = null;
  }

  Future<void> updateAnswers(Map<int, String?> answers) async {
    if (_session == null) return;
    _session = ExamSessionData(
      examId: _session!.examId,
      examTitle: _session!.examTitle,
      durationMinutes: _session!.durationMinutes,
      startTimestamp: _session!.startTimestamp,
      selectedAnswers: Map.from(answers),
      expiresAt: _session!.expiresAt,
    );
  }
}
