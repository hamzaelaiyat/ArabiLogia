import 'package:drift/drift.dart';

class CachedExams extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get subjectId => text()();
  IntColumn get grade => integer()();
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
