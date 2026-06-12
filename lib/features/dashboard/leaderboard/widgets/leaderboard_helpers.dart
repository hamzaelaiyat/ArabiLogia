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
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    final first = parts[0].isNotEmpty ? parts[0].substring(0, 1) : '';
    final second = parts[1].isNotEmpty ? parts[1].substring(0, 1) : '';
    return '$first$second';
  }
  return name.trim().isNotEmpty ? name.trim().substring(0, 1) : 'ط';
}
