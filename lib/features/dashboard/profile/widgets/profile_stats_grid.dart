import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class ProfileStatsGrid extends StatelessWidget {
  const ProfileStatsGrid({
    super.key,
    required this.examsCompleted,
    required this.avgScore,
    required this.totalScore,
  });

  final dynamic examsCompleted;
  final dynamic avgScore;
  final dynamic totalScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.spacing24),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppTokens.radius2xlAll,
        boxShadow: null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: '$examsCompleted',
            label: 'امتحانات',
            icon: Icons.assignment_outlined,
          ),
          _StatDivider(),
          _StatItem(
            value: '${((avgScore as num).toInt())}%',
            label: 'المتوسط',
            icon: Icons.analytics_outlined,
          ),
          _StatDivider(),
          _StatItem(
            value: '${((totalScore as num).toInt())}',
            label: 'نقاط',
            icon: Icons.emoji_events_outlined,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.primary.withValues(alpha: 0.1),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary.withValues(alpha: 0.7), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.foreground(context),
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.mutedColor(context),
          ),
        ),
      ],
    );
  }
}
