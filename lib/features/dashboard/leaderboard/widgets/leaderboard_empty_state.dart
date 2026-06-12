import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class LeaderboardEmptyState extends StatelessWidget {
  const LeaderboardEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 64,
            color: AppColors.mutedColor(context).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد متصدرين لهذا الصف حالياً',
            style: TextStyle(color: AppColors.mutedColor(context)),
          ),
        ],
      ),
    );
  }
}
