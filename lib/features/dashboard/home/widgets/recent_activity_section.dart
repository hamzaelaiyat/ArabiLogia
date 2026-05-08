import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'activity_tile.dart';

class RecentActivitySection extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  final bool isLoading;

  const RecentActivitySection({
    super.key,
    required this.activities,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'النشاط الأخير',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (activities.isNotEmpty)
              TextButton(
                onPressed: () => context.go(AppRoutes.activityHistory),
                child: const Text(
                  'مشاهدة الكل',
                  style: TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.spacing8),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTokens.spacing16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (activities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTokens.spacing16),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: AppTokens.radiusLgAll,
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 48,
                    color: AppColors.mutedColor(context).withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppTokens.spacing8),
                  Text(
                    'لا يوجد نشاط مؤخراً',
                    style: TextStyle(color: AppColors.mutedColor(context)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ابدأ اختباراً الآن لترى إنجازاتك',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedColor(context).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: activities.map((activity) {
              return ActivityTile(activity: activity);
            }).toList(),
          ),
      ],
    );
  }
}
