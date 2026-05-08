import 'package:flutter/material.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';

class ExamResultsCard extends StatelessWidget {
  final Map<String, dynamic> exam;
  final VoidCallback onTap;
  final VoidCallback onUnpublish;

  const ExamResultsCard({
    super.key,
    required this.exam,
    required this.onTap,
    required this.onUnpublish,
  });

  static const _gradeNames = [
    '',
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
    'السابع',
    'الثامن',
    'التاسع',
    'العاشر',
    'الحادي عشر',
    'الثاني عشر',
  ];

  @override
  Widget build(BuildContext context) {
    final subjectId = exam['subject_id'] as String? ?? '';
    final category = CategoryMetadata.getById(subjectId);
    final subjectName = category?.name ?? exam['subject_id'] ?? 'غير محدد';
    final grade = exam['grade'] as int? ?? 0;
    final gradeText = grade == 0
        ? 'جميع الصفوف'
        : 'صف ${_gradeNames[grade.clamp(0, 12)]}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEB8A00),
          child: Icon(Icons.quiz, color: Colors.white),
        ),
        title: Text(exam['title'] ?? 'بدون عنوان'),
        subtitle: Text('القسم: $subjectName - $gradeText'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: onUnpublish,
              tooltip: 'إلغاء النشر',
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}