import 'package:drift/drift.dart';
import '../tables.dart';
import '../database.dart';

part 'exam_dao.g.dart';

@DriftAccessor(tables: [CachedExams])
class ExamDao extends DatabaseAccessor<AppDatabase> with _$ExamDaoMixin {
  ExamDao(super.attachedDatabase);

  Future<void> cacheExam(CachedExamsCompanion exam) =>
      into(cachedExams).insertOnConflictUpdate(exam);

  Future<CachedExam?> getCachedExam(String id) =>
      (select(cachedExams)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> removeCachedExam(String id) =>
      (delete(cachedExams)..where((t) => t.id.equals(id))).go();

  Future<void> clearExpiredCache(Duration maxAge) async {
    final cutoff = DateTime.now().subtract(maxAge);
    await (delete(cachedExams)..where((t) => t.downloadedAt.isSmallerThan(Variable(cutoff)))).go();
  }
}
