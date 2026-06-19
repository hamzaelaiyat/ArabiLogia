import 'package:drift/drift.dart';
import '../tables.dart';
import '../database_io.dart';

part 'exam_dao.g.dart';

@DriftAccessor(tables: [CachedExams])
class ExamDao extends DatabaseAccessor<AppDatabase> with _$ExamDaoMixin {
  ExamDao(super.attachedDatabase);

  Future<void> cacheExamFields({
    required String id,
    required String title,
    required String subjectId,
    required int grade,
    required String data,
  }) =>
      into(cachedExams).insertOnConflictUpdate(
        CachedExamsCompanion(
          id: Value(id),
          title: Value(title),
          subjectId: Value(subjectId),
          grade: Value(grade),
          data: Value(data),
          downloadedAt: Value(DateTime.now()),
        ),
      );

  Future<CachedExam?> getCachedExam(String id) =>
      (select(cachedExams)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<CachedExam>> getCachedExamsBySubject(String subjectId, int grade) =>
      (select(cachedExams)
        ..where((t) => t.subjectId.equals(subjectId))
        ..where((t) => t.grade.equals(grade))
      ).get();

  Future<void> removeCachedExam(String id) =>
      (delete(cachedExams)..where((t) => t.id.equals(id))).go();

  Future<void> clearExpiredCache(Duration maxAge) async {
    final cutoff = DateTime.now().subtract(maxAge);
    await (delete(cachedExams)..where((t) => t.downloadedAt.isSmallerThan(Variable(cutoff)))).go();
  }
}
