import 'package:drift/drift.dart';
import 'package:arabilogia/core/models/grade_metadata.dart';
import '../tables.dart';
import '../database_io.dart';

part 'exam_dao_io.g.dart';

@DriftAccessor(tables: [CachedExams])
class ExamDao extends DatabaseAccessor<AppDatabase> with _$ExamDaoMixin {
  ExamDao(super.attachedDatabase);

  Future<void> cacheExamFields({
    required String id,
    required String title,
    required String subjectId,
    required int grade,
    required List<int> gradeIds,
    required String data,
  }) => into(cachedExams).insertOnConflictUpdate(
    CachedExamsCompanion(
      id: Value(id),
      title: Value(title),
      subjectId: Value(subjectId),
      grade: Value(grade),
      gradeIds: Value(GradeMetadata.encodeGradeIdsCsv(gradeIds)),
      data: Value(data),
      downloadedAt: Value(DateTime.now()),
    ),
  );

  Future<CachedExam?> getCachedExam(String id) =>
      (select(cachedExams)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Returns every cached exam for [subjectId] that is shared with [grade].
  /// A shared exam is stored once but must surface for all of its grades, so
  /// the match runs against `grade_ids` rather than the legacy scalar column.
  Future<List<CachedExam>> getCachedExamsBySubject(
    String subjectId,
    int grade,
  ) async {
    final rows = await (select(
      cachedExams,
    )..where((t) => t.subjectId.equals(subjectId))).get();
    return rows
        .where(
          (row) => GradeMetadata.isVisibleToGrade(
            GradeMetadata.decodeGradeIdsCsv(row.gradeIds, legacyGrade: row.grade),
            grade,
          ),
        )
        .toList();
  }

  Future<void> removeCachedExam(String id) =>
      (delete(cachedExams)..where((t) => t.id.equals(id))).go();

  Future<void> clearExpiredCache(Duration maxAge) async {
    final cutoff = DateTime.now().subtract(maxAge);
    await (delete(
      cachedExams,
    )..where((t) => t.downloadedAt.isSmallerThan(Variable(cutoff)))).go();
  }
}
