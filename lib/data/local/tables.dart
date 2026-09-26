import 'package:drift/drift.dart';

class CachedExams extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get subjectId => text()();
  IntColumn get grade => integer()();

  /// Comma-separated grade ids this exam is shared with (e.g. "1,10,12").
  /// Stored as text so the local cache keeps working offline without needing
  /// array support; `0` means shared with every grade.
  TextColumn get gradeIds => text().withDefault(const Constant(''))();
  TextColumn get data => text()();
  DateTimeColumn get downloadedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ExamScores extends Table {
  TextColumn get examId => text()();
  RealColumn get score => real()();
  IntColumn get points => integer()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {examId};
}

@DataClassName('ExamSessionRow')
class ExamSessions extends Table {
  TextColumn get examId => text()();
  TextColumn get examTitle => text()();
  IntColumn get durationMinutes => integer()();
  IntColumn get startTimestamp => integer()();
  TextColumn get selectedAnswers => text()();
  IntColumn get expiresAt => integer()();

  @override
  Set<Column> get primaryKey => {examId};
}
