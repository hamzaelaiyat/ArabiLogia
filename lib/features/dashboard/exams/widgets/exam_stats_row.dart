import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';

class ExamStatsRow extends StatelessWidget {
  final int questionCount;
  final int? durationMinutes;
  final String subjectId;

  const ExamStatsRow({
    super.key,
    required this.questionCount,
    required this.durationMinutes,
    required this.subjectId,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatItem(
          context,
          '$questionCount',
          'سؤال',
          Icons.help_outline,
        ),
        const SizedBox(width: AppTokens.spacing16),
        _buildStatItem(
          context,
          '$durationMinutes',
          'دقيقة',
          Icons.timer_outlined,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final color = CategoryMetadata.categories
        .firstWhere((c) => c.id == subjectId)
        .color;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: AppTokens.radiusLgAll,
          border: Border.all(color: color.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppTokens.spacing12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
