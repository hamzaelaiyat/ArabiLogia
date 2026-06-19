import 'daos/exam_dao_web.dart';
import 'daos/score_dao_web.dart';
import 'daos/session_dao_web.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  AppDatabase.forTesting(void e);

  final examDao = ExamDao();
  final scoreDao = ScoreDao();
  final sessionDao = SessionDao();
}
