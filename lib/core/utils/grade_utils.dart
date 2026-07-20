String getGradeText(dynamic grade, {String fallback = 'صفك الدراسي'}) {
  if (grade == null) return fallback;
  final g = grade is int ? grade : int.tryParse(grade.toString()) ?? 0;
  switch (g) {
    case 10:
      return 'الأولى باكالوريا';
    case 11:
      return 'الثانية ثانوي';
    case 12:
      return 'الثالثة ثانوي';
    default:
      return fallback;
  }
}
