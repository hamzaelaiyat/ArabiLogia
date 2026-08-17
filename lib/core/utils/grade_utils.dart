import 'package:arabilogia/core/models/grade_metadata.dart';

/// Label for a grade id (from the `grades` table), falling back to a
/// bundled default while the table is still loading or offline.
String gradeLabel(int gradeId) =>
    GradeMetadata.getById(gradeId)?.name ?? 'صفك الدراسي';

String getGradeText(dynamic grade, {String fallback = 'صفك الدراسي'}) {
  if (grade == null) return fallback;
  final g = grade is int ? grade : int.tryParse(grade.toString()) ?? 0;
  return GradeMetadata.getById(g)?.name ?? fallback;
}
