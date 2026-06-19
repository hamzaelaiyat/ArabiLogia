String getGradeName(int grade) {
  switch (grade) {
    case 10:
      return 'الأولى باكالوريا';
    case 11:
      return 'الثانية ثانوي';
    case 12:
      return 'الثالثة ثانوي';
    default:
      return 'كل الصفوف';
  }
}

int getGradeValueFromLabel(String label) {
  if (label.contains('الأول')) return 10;
  if (label.contains('الثاني')) return 11;
  if (label.contains('الثالث')) return 12;
  return 0;
}

String getAvatar(String name) {
  if (name.trim().isEmpty) return 'ط';
  return name.trim().substring(0, 1);
}
