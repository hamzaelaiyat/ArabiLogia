import 'package:drift/drift.dart';
import '../tables.dart';
import '../database.dart';

part 'score_dao.g.dart';

@DriftAccessor(tables: [ExamScores])
class ScoreDao extends DatabaseAccessor<AppDatabase> with _$ScoreDaoMixin {
  ScoreDao(super.attachedDatabase);

  Future<void> upsertScore(String examId, double score, int points) =>
      into(examScores).insertOnConflictUpdate(
        ExamScoresCompanion(
          examId: Value(examId),
          score: Value(score),
          points: Value(points),
        ),
      );

  Future<Map<String, Map<String, dynamic>>> getAllScores() async {
    final scores = await select(examScores).get();
    return {
      for (final s in scores)
        s.examId: {
          'score': s.score,
          'points': s.points,
          'synced': s.synced,
        },
    };
  }

  Future<void> markSynced(String examId) =>
      (update(examScores)..where((t) => t.examId.equals(examId)))
        .write(const ExamScoresCompanion(synced: Value(true)));

  Future<List<ExamScore>> getUnsyncedScores() =>
      (select(examScores)..where((t) => t.synced.equals(false))).get();
}
