// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_dao_io.dart';

// ignore_for_file: type=lint
mixin _$SessionDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExamSessionsTable get examSessions => attachedDatabase.examSessions;
  SessionDaoManager get managers => SessionDaoManager(this);
}

class SessionDaoManager {
  final _$SessionDaoMixin _db;
  SessionDaoManager(this._db);
  $$ExamSessionsTableTableManager get examSessions =>
      $$ExamSessionsTableTableManager(_db.attachedDatabase, _db.examSessions);
}
