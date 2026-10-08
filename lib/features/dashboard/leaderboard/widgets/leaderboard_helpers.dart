import 'package:arabilogia/core/models/grade_metadata.dart';
import 'package:arabilogia/core/utils/grade_utils.dart';

String getGradeName(int grade) {
  if (grade == GradeMetadata.allGrades) return 'كل الصفوف';
  return getGradeText(grade);
}

String getAvatar(String name) {
  if (name.trim().isEmpty) return 'ط';
  return name.trim().substring(0, 1);
}

String shortenFullName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'طالبنا';
  final parts = trimmed
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.length <= 2) return parts.join(' ');
  return parts.take(2).join(' ');
}

/// Splits an already-sorted leaderboard into the podium and the rows below it.
///
/// Partitioning must be by list position, never by the `rank` column: SQL
/// `RANK()` gives every tied user the same rank, so a board full of ties
/// would push all rows into the podium and leave the rank-4+ list empty.
({List<Map<String, dynamic>> podium, List<Map<String, dynamic>> rest})
    partitionLeaderboard(
  List<Map<String, dynamic>> rows, {
  int podiumSize = 3,
}) {
  return (
    podium: rows.take(podiumSize).toList(),
    rest: rows.skip(podiumSize).toList(),
  );
}
