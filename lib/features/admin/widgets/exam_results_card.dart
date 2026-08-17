import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';

class ExamResultsCard extends StatelessWidget {
  final Map<String, dynamic> exam;
  final VoidCallback onTap;
  final VoidCallback? onPublish;
  final VoidCallback? onEdit;
  final VoidCallback onUnpublish;

  const ExamResultsCard({
    super.key,
    required this.exam,
    required this.onTap,
    this.onPublish,
    this.onEdit,
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

  bool get _isPublished {
    final data = exam['data'];
    if (data is Map<String, dynamic>) {
      return data['p'] == 1;
    }
    return true;
  }

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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _isPublished ? const Color(0xFFEB8A00) : Colors.orange.shade200,
              child: const Icon(Icons.quiz, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          exam['title'] ?? 'بدون عنوان',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isPublished ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _isPublished ? Colors.green.shade300 : Colors.orange.shade300,
                          ),
                        ),
                        child: Text(
                          _isPublished ? 'منشور' : 'مسودة',
                          style: TextStyle(
                            fontSize: 11,
                            color: _isPublished ? Colors.green.shade700 : Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'القسم: $subjectName - $gradeText',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedColor(context),
                    ),
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
                tooltip: 'تعديل',
                color: AppColors.primary,
                visualDensity: VisualDensity.compact,
              ),
            if (!_isPublished && onPublish != null)
              IconButton(
                icon: const Icon(Icons.publish, size: 20),
                onPressed: onPublish,
                tooltip: 'نشر',
                color: Colors.green,
                visualDensity: VisualDensity.compact,
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onUnpublish,
              tooltip: 'حذف',
              color: Colors.grey,
              visualDensity: VisualDensity.compact,
            ),
            const Icon(Icons.chevron_left, size: 20),
          ],
        ),
        ),
      ),
    );
  }
}