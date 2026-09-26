import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';

class ActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityTile({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final isLecture = activity['type'] == 'lecture';
    final subject = activity['subject']?.toString() ?? '';
    final categoryId = activity['category_id']?.toString();
    final category = categoryId != null && categoryId.isNotEmpty
        ? CategoryMetadata.getById(categoryId)
        : CategoryMetadata.getByName(subject);
    final accent = isLecture
        ? AppColors.blue
        : (category?.color ?? AppColors.primary);

    final title = isLecture
        ? activity['title']?.toString() ??
              (activity['category_name']?.toString() ?? subject)
        : (subject.isNotEmpty ? subject : 'اختبار');
    final subtitle = isLecture ? activity['category_name']?.toString() : null;

    return Semantics(
      label:
          '$title${subtitle != null ? '، $subtitle' : ''}${isLecture ? '' : '، درجة ${activity['score']}'}',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTokens.spacing8),
        padding: const EdgeInsets.all(AppTokens.spacing12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: AppTokens.radiusLgAll,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLecture
                    ? (category?.icon ?? Icons.play_circle_outline)
                    : (category?.icon ?? Icons.quiz_outlined),
                color: accent,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTokens.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedColor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    _getTimeAgo(activity['created_at']?.toString()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedColor(context),
                    ),
                  ),
                ],
              ),
            ),
            if (isLecture)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: AppTokens.radiusFullAll,
                ),
                child: const Text(
                  'محاضرة',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: AppTokens.radiusFullAll,
                ),
                child: Text(
                  '${(activity['score'] as num).toInt()}%',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
      return 'منذ فترة';
    } catch (e) {
      return '';
    }
  }
}
