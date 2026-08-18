import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_text_styles.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class LectureHeroCard extends StatelessWidget {
  final String title;
  final String description;
  final Color categoryColor;
  final int questionCount;
  final String durationLabel;
  final VoidCallback onMarkAllRead;
  final VoidCallback onResetProgress;

  const LectureHeroCard({
    super.key,
    required this.title,
    required this.description,
    required this.categoryColor,
    required this.questionCount,
    required this.durationLabel,
    required this.onMarkAllRead,
    required this.onResetProgress,
  });

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing6,
        vertical: AppTokens.spacing2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: AppTokens.radiusFullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppTokens.iconSizeXs, color: Colors.white),
          const SizedBox(width: AppTokens.spacing2),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.spacing16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [categoryColor, categoryColor.withValues(alpha: 0.65)],
        ),
        borderRadius: AppTokens.radiusLgAll,
        boxShadow: [
          BoxShadow(
            color: categoryColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headingMd.copyWith(color: Colors.white),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spacing4),
            Text(
              description,
              style: AppTextStyles.bodyMd.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppTokens.spacing8),
          Wrap(
            spacing: AppTokens.spacing4,
            runSpacing: AppTokens.spacing4,
            children: [
              _statChip(Icons.schedule, durationLabel),
              if (questionCount > 0)
                _statChip(Icons.help_outline, '$questionCount سؤال'),
            ],
          ),
          const SizedBox(height: AppTokens.spacing8),
          Wrap(
            spacing: AppTokens.spacing4,
            runSpacing: AppTokens.spacing4,
            children: [
              TextButton.icon(
                onPressed: onMarkAllRead,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.done_all, size: AppTokens.iconSizeXs),
                label: const Text('تحديد الكل كمقروء'),
              ),
              TextButton.icon(
                onPressed: onResetProgress,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.85),
                ),
                icon: const Icon(Icons.restart_alt, size: AppTokens.iconSizeXs),
                label: const Text('إعادة تعيين التقدم'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
