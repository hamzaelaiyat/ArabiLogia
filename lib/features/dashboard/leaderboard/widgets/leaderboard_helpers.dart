import 'package:arabilogia/core/utils/grade_utils.dart';

String getGradeName(int grade) {
  if (grade == 0) return 'كل الصفوف';
  return getGradeText(grade);
}

int getGradeValueFromLabel(String label) {
  if (label.contains('الأول')) return 1;
  if (label.contains('الثاني')) return 2;
  if (label.contains('الثالث')) return 3;
  return 0;
}

String getAvatar(String name) {
  if (name.trim().isEmpty) return 'ط';
  return name.trim().substring(0, 1);
}
