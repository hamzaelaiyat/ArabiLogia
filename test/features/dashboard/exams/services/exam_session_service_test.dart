import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:arabilogia/data/local/database.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_session.dart';
import 'package:arabilogia/features/dashboard/exams/services/exam_session_service.dart';

ExamSession _createSession({
  String examId = 'exam_1',
  String examTitle = 'Test Exam',
  int durationMinutes = 30,
  int? startTimestamp,
  Map<int, String?>? selectedAnswers,
}) {
  return ExamSession(
    examId: examId,
    examTitle: examTitle,
    durationMinutes: durationMinutes,
    startTimestamp:
        startTimestamp ?? DateTime.now().millisecondsSinceEpoch,
    selectedAnswers: selectedAnswers ?? const {},
  );
}

void main() {
  late AppDatabase db;
  late ExamSessionService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = ExamSessionService(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('saveSession', () {
    test('persists session to database', () async {
      final session = _createSession();

      await service.saveSession(session);

      final saved = await service.getSession();
      expect(saved, isNotNull);
      expect(saved!.examId, equals(session.examId));
      expect(saved.examTitle, equals(session.examTitle));
      expect(saved.durationMinutes, equals(session.durationMinutes));
      expect(saved.startTimestamp, equals(session.startTimestamp));
      expect(saved.selectedAnswers, equals(session.selectedAnswers));
    });
  });

  group('getSession', () {
    test('returns null when no session saved', () async {
      final result = await service.getSession();

      expect(result, isNull);
    });

    test('returns parsed session when valid data exists', () async {
      final session = _createSession(
        selectedAnswers: {1: 'A', 2: null},
      );
      await service.saveSession(session);

      final result = await service.getSession();

      expect(result, isNotNull);
      expect(result!.examId, equals(session.examId));
      expect(result.examTitle, equals(session.examTitle));
      expect(result.durationMinutes, equals(session.durationMinutes));
      expect(result.startTimestamp, equals(session.startTimestamp));
      expect(result.selectedAnswers, equals(session.selectedAnswers));
    });

    test('returns null when session is expired and clears storage', () async {
      final session = _createSession(
        durationMinutes: 1,
        startTimestamp: DateTime.now()
            .subtract(const Duration(minutes: 2))
            .millisecondsSinceEpoch,
      );
      await service.saveSession(session);

      final result = await service.getSession();

      expect(result, isNull);
      final again = await service.getSession();
      expect(again, isNull);
    });

    test('handles malformed selectedAnswers gracefully', () async {
      await db.into(db.examSessions).insert(const ExamSessionsCompanion(
        examId: Value('bad'),
        examTitle: Value('Bad'),
        durationMinutes: Value(10),
        startTimestamp: Value(0),
        selectedAnswers: Value('not valid json'),
        expiresAt: Value(0),
      ));

      final result = await service.getSession();
      expect(result, isNull);
      final cleaned = await db.select(db.examSessions).get();
      expect(cleaned, isEmpty);
    });
  });

  group('updateAnswers', () {
    test('loads current session, updates answers, saves back', () async {
      final session = _createSession(selectedAnswers: {1: 'A'});
      await service.saveSession(session);

      await service.updateAnswers({1: 'B', 2: 'C'});

      final updated = await service.getSession();
      expect(updated, isNotNull);
      expect(updated!.selectedAnswers[1], equals('B'));
      expect(updated.selectedAnswers[2], equals('C'));
    });

    test('does nothing when no session exists', () async {
      await service.updateAnswers({1: 'A'});

      final result = await service.getSession();
      expect(result, isNull);
    });
  });

  group('refreshStartTime', () {
    test('updates startTimestamp to current time', () async {
      final oldTimestamp = DateTime.now()
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch;
      final session = _createSession(
        durationMinutes: 120,
        startTimestamp: oldTimestamp,
      );
      await service.saveSession(session);

      await service.refreshStartTime();

      final updated = await service.getSession();
      expect(updated, isNotNull);
      expect(updated!.startTimestamp, greaterThan(oldTimestamp));
      expect(
        (DateTime.now().millisecondsSinceEpoch - updated.startTimestamp).abs(),
        lessThan(5000),
      );
    });

    test('does nothing when no session exists', () async {
      await service.refreshStartTime();

      final result = await service.getSession();
      expect(result, isNull);
    });
  });

  group('clearSession', () {
    test('removes the session from database', () async {
      final session = _createSession();
      await service.saveSession(session);

      await service.clearSession();

      final result = await service.getSession();
      expect(result, isNull);
    });
  });

  group('hasInProgressExam', () {
    test('returns true when session exists', () async {
      final session = _createSession();
      await service.saveSession(session);

      final result = await service.hasInProgressExam();

      expect(result, isTrue);
    });

    test('returns false when no session exists', () async {
      final result = await service.hasInProgressExam();

      expect(result, isFalse);
    });
  });

  group('formatRemainingTime', () {
    test('returns 00:00 for 0 seconds', () {
      expect(service.formatRemainingTime(0), equals('00:00'));
    });

    test('returns 00:00 for negative seconds', () {
      expect(service.formatRemainingTime(-10), equals('00:00'));
    });

    test('returns 15:30 for 930 seconds', () {
      expect(service.formatRemainingTime(930), equals('15:30'));
    });

    test('returns 01:05 for 65 seconds', () {
      expect(service.formatRemainingTime(65), equals('01:05'));
    });

    test('returns 59:59 for 3599 seconds', () {
      expect(service.formatRemainingTime(3599), equals('59:59'));
    });

    test('pads single digit minutes with leading zero', () {
      expect(service.formatRemainingTime(5), equals('00:05'));
    });

    test('pads single digit seconds with leading zero', () {
      expect(service.formatRemainingTime(61), equals('01:01'));
    });
  });
}
