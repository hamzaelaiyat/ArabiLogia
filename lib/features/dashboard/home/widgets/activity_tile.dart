import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';

class ActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityTile({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final category = CategoryMetadata.getByName(activity['subject']);

    return Container(
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
              color: (category?.color ?? AppColors.primary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              category?.icon ?? Icons.quiz_outlined,
              color: category?.color ?? AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTokens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['subject'] ?? 'اختبار',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _getTimeAgo(activity['created_at']),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedColor(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppTokens.radiusFullAll,
            ),
            child: Text(
              '${(activity['score'] as num).toInt()}%',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
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
