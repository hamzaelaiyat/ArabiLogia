// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_dao_io.dart';

// ignore_for_file: type=lint
mixin _$ExamDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedExamsTable get cachedExams => attachedDatabase.cachedExams;
  ExamDaoManager get managers => ExamDaoManager(this);
}

class ExamDaoManager {
  final _$ExamDaoMixin _db;
  ExamDaoManager(this._db);
  $$CachedExamsTableTableManager get cachedExams =>
      $$CachedExamsTableTableManager(_db.attachedDatabase, _db.cachedExams);
}
