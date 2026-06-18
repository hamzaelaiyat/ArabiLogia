import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'tables.dart';
import 'daos/exam_dao.dart';
import 'daos/score_dao.dart';
import 'daos/session_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [CachedExams, ExamScores, ExamSessions],
  daos: [ExamDao, ScoreDao, SessionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {},
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
