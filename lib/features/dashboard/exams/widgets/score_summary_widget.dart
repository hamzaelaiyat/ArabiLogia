import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class ScoreSummaryWidget extends StatelessWidget {
  final int score;
  final bool isPassed;

  const ScoreSummaryWidget({
    super.key,
    required this.score,
    required this.isPassed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.spacing32),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppTokens.radiusLgAll,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 10,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'الدرجة النهائية',
                    style: TextStyle(fontSize: 10, color: AppColors.mutedColor(context)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            isPassed
                ? 'تهانينا! لقد اجتزت الاختبار'
                : 'حاول مرة أخرى لتحسين مستواك',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
