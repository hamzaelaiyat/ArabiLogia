// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score_dao.dart';

// ignore_for_file: type=lint
mixin _$ScoreDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExamScoresTable get examScores => attachedDatabase.examScores;
  ScoreDaoManager get managers => ScoreDaoManager(this);
}

class ScoreDaoManager {
  final _$ScoreDaoMixin _db;
  ScoreDaoManager(this._db);
  $$ExamScoresTableTableManager get examScores =>
      $$ExamScoresTableTableManager(_db.attachedDatabase, _db.examScores);
}
