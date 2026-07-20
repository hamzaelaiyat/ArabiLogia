import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class StatsRowWidget extends StatelessWidget {
  final int totalQuestions;
  final int correctCount;
  final int accuracy;
  final int speedBonus;

  const StatsRowWidget({
    super.key,
    required this.totalQuestions,
    required this.correctCount,
    required this.accuracy,
    required this.speedBonus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatCard(
          context,
          'الأسئلة',
          '$totalQuestions',
          Icons.quiz_outlined,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          context,
          'الصحيحة',
          '$correctCount',
          Icons.check_circle_outline,
        ),
        const SizedBox(width: 8),
        _buildStatCard(context, 'الدقة', '$accuracy%', Icons.percent),
        const SizedBox(width: 8),
        _buildStatCard(
          context,
          'النقاط',
          '+$speedBonus',
          Icons.bolt,
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: AppTokens.radiusMdAll,
          border: Border.all(
            color: (color ?? AppColors.primary).withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color ?? AppColors.primary),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: AppColors.mutedColor(context)),
            ),
          ],
        ),
      ),
    );
  }
}
