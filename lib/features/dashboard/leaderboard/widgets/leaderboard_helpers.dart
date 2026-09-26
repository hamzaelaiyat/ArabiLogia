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
