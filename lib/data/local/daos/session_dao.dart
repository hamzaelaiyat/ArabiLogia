import 'dart:convert';
import 'package:drift/drift.dart';
import '../tables.dart';
import '../database.dart';
import '../models/exam_session_data.dart';

part 'session_dao.g.dart';

@DriftAccessor(tables: [ExamSessions])
class SessionDao extends DatabaseAccessor<AppDatabase> with _$SessionDaoMixin {
  SessionDao(super.attachedDatabase);

  Future<void> saveSession(ExamSessionData session) =>
      into(examSessions).insertOnConflictUpdate(
        ExamSessionsCompanion(
          examId: Value(session.examId),
          examTitle: Value(session.examTitle),
          durationMinutes: Value(session.durationMinutes),
          startTimestamp: Value(session.startTimestamp),
          selectedAnswers: Value(jsonEncode(
            session.selectedAnswers.map((k, v) => MapEntry(k.toString(), v)),
          )),
          expiresAt: Value(session.expiresAt),
        ),
      );

  Future<ExamSessionData?> getSession() async {
    final row = await (select(examSessions)
      ..orderBy([(t) => OrderingTerm(expression: t.startTimestamp, mode: OrderingMode.desc)])
      ..limit(1)
    ).getSingleOrNull();

    if (row == null) return null;

    return ExamSessionData(
      examId: row.examId,
      examTitle: row.examTitle,
      durationMinutes: row.durationMinutes,
      startTimestamp: row.startTimestamp,
      selectedAnswers: (jsonDecode(row.selectedAnswers) as Map<String, dynamic>)
          .map((k, v) => MapEntry(int.parse(k), v as String?)),
      expiresAt: row.expiresAt,
    );
  }

  Future<void> deleteSession() async {
    await delete(examSessions).go();
  }

  Future<void> updateAnswers(Map<int, String?> answers) async {
    final session = await getSession();
    if (session == null) return;
    final encoded = jsonEncode(answers.map((k, v) => MapEntry(k.toString(), v)));
    await (update(examSessions)..where((t) => t.examId.equals(session.examId)))
      .write(ExamSessionsCompanion(selectedAnswers: Value(encoded)));
  }
}
