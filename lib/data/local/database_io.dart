import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'tables.dart';
import 'daos/exam_dao_io.dart';
import 'daos/score_dao_io.dart';
import 'daos/session_dao_io.dart';

part 'database_io.g.dart';

@DriftDatabase(
  tables: [CachedExams, ExamScores, ExamSessions],
  daos: [ExamDao, ScoreDao, SessionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static final AppDatabase instance = AppDatabase._();

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2 added cached_exams.grade_ids so shared exams stay discoverable
        // offline. Backfill from the legacy scalar column: grade 0 meant
        // "every grade", so it maps to the 0 sentinel.
        await m.addColumn(
          cachedExams,
          cachedExams.gradeIds,
        );
        await customStatement(
          "UPDATE cached_exams SET grade_ids = "
          "CASE WHEN grade = 0 THEN '0' ELSE CAST(grade AS TEXT) END",
        );
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'arabilogia.db'));
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    return NativeDatabase(file);
  });
}
