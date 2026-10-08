import 'package:flutter/material.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/models/grade_metadata.dart';
import 'package:arabilogia/core/utils/grade_utils.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';

/// Actions offered by the lecture card's overflow (3-dots) menu.
enum LectureCardAction { edit, publish, unpublish, viewResults, delete }

class ExamResultsCard extends StatelessWidget {
  final Map<String, dynamic> exam;
  final VoidCallback? onTap;
  final VoidCallback? onPublish;
  final VoidCallback? onEdit;
  final VoidCallback? onUnpublish;
  final VoidCallback? onViewResults;
  final VoidCallback? onDelete;

  const ExamResultsCard({
    super.key,
    required this.exam,
    required this.onTap,
    this.onPublish,
    this.onEdit,
    this.onUnpublish,
    this.onViewResults,
    this.onDelete,
  });

  bool get _isPublished {
    if (exam.containsKey('is_published')) {
      return exam['is_published'] == true;
    }
    final data = exam['data'];
    if (data is Map<String, dynamic>) {
      return data['p'] == 1;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final subjectId =
        (exam['course_id'] ?? exam['subject_id']) as String? ?? '';
    final category = CategoryMetadata.getById(subjectId);
    final subjectName = category?.name ?? subjectId;
    final grade = exam['grade'] as int? ?? GradeMetadata.allGrades;
    final gradeText = grade == GradeMetadata.allGrades
        ? 'جميع الصفوف'
        : gradeLabel(grade);

    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _isPublished
                ? AppColors.primary
                : Colors.orange.shade200,
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 20,
            ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _isPublished
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _isPublished
                              ? Colors.green.shade300
                              : Colors.orange.shade300,
                        ),
                      ),
                      child: Text(
                        _isPublished ? 'منشور' : 'مسودة',
                        style: TextStyle(
                          fontSize: 11,
                          color: _isPublished
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
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
          _OverflowMenu(
            isPublished: _isPublished,
            onAction: (action) {
              switch (action) {
                case LectureCardAction.edit:
                  onEdit?.call();
                case LectureCardAction.publish:
                  onPublish?.call();
                case LectureCardAction.unpublish:
                  onUnpublish?.call();
                case LectureCardAction.viewResults:
                  onViewResults?.call();
                case LectureCardAction.delete:
                  onDelete?.call();
              }
            },
          ),
          const Icon(Icons.chevron_left, size: 20),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: onTap != null
          ? InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: child,
            )
          : child,
    );
  }
}

/// The 3-dots button that replaced the four inline action icons. Publish and
/// unpublish stay mutually exclusive so the menu never offers both.
class _OverflowMenu extends StatelessWidget {
  final bool isPublished;
  final ValueChanged<LectureCardAction> onAction;

  const _OverflowMenu({required this.isPublished, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<LectureCardAction>(
      key: TestKeys.teacherLectureActions,
      tooltip: 'خيارات المحاضرة',
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: onAction,
      shape: RoundedRectangleBorder(borderRadius: AppTokens.radiusMdAll),
      itemBuilder: (context) => [
        if (!isPublished)
          const PopupMenuItem(
            value: LectureCardAction.publish,
            child: _MenuRow(
              icon: Icons.publish,
              label: 'نشر المحاضرة',
              color: AppColors.success,
            ),
          ),
        if (isPublished)
          const PopupMenuItem(
            value: LectureCardAction.unpublish,
            child: _MenuRow(
              icon: Icons.unpublished_outlined,
              label: 'تحويل إلى مسودة',
              color: AppColors.examWarning,
            ),
          ),
        const PopupMenuItem(
          value: LectureCardAction.viewResults,
          child: _MenuRow(
            icon: Icons.insights_outlined,
            label: 'عرض نتائج الامتحانات',
            color: AppColors.blue,
          ),
        ),
        const PopupMenuItem(
          value: LectureCardAction.edit,
          child: _MenuRow(
            icon: Icons.edit_outlined,
            label: 'تعديل المحاضرة',
            color: AppColors.primary,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: LectureCardAction.delete,
          child: _MenuRow(
            icon: Icons.delete_outline,
            label: 'حذف المحاضرة',
            color: AppColors.error,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppTokens.spacing4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: AppTokens.fontSizeMd),
        ),
      ],
    );
  }
}
