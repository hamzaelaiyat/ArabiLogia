String formatArabicDate(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  } catch (e) {
    return isoDate;
  }
}

String formatLastExamDate(String? isoDate) {
  if (isoDate == null) return 'لم تؤدِّ أي امتحان بعد';
  try {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';

    return formatArabicDate(isoDate);
  } catch (e) {
    return isoDate;
  }
}
