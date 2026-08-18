import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_text_styles.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class ProgressSegmentData {
  final String label;
  final IconData icon;
  final int total;
  final int completed;
  final Color color;

  const ProgressSegmentData({
    required this.label,
    required this.icon,
    required this.total,
    required this.completed,
    required this.color,
  });
}

class ProgressBarCard extends StatelessWidget {
  final List<ProgressSegmentData> segments;
  final Color categoryColor;

  const ProgressBarCard({
    super.key,
    required this.segments,
    required this.categoryColor,
  });

  int get _total => segments.fold(0, (sum, s) => sum + s.total);
  int get _completed => segments.fold(0, (sum, s) => sum + s.completed);
  double get _overallRatio => _total == 0 ? 0.0 : (_completed / _total).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty || _total == 0) return const SizedBox.shrink();

    final percentageInt = (_overallRatio * 100).round();
    final isFullyCompleted = _completed == _total;

    return Card(
      elevation: 2,
      shadowColor: categoryColor.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: AppTokens.radiusLgAll),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFullyCompleted
                            ? Icons.verified_rounded
                            : Icons.insights_rounded,
                        size: 18,
                        color: categoryColor,
                      ),
                    ),
                    const SizedBox(width: AppTokens.spacing8),
                    Text(
                      'تقدمك في المحاضرة',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.12),
                    borderRadius: AppTokens.radiusFullAll,
                  ),
                  child: Text(
                    '$percentageInt% مكتمل',
                    style: TextStyle(
                      color: categoryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacing12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppColors.mutedColor(context).withValues(alpha: 0.12),
                    ),
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: _overallRatio,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              categoryColor,
                              categoryColor.withValues(alpha: 0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacing12),
            Wrap(
              spacing: AppTokens.spacing8,
              runSpacing: AppTokens.spacing6,
              children: [
                for (final segment in segments)
                  if (segment.total > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spacing8,
                        vertical: AppTokens.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: segment.color.withValues(alpha: 0.08),
                        borderRadius: AppTokens.radiusSmAll,
                        border: Border.all(
                          color: segment.color.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            segment.icon,
                            size: 14,
                            color: segment.color,
                          ),
                          const SizedBox(width: AppTokens.spacing4),
                          Text(
                            segment.label,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.foreground(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppTokens.spacing4),
                          Text(
                            '${segment.completed}/${segment.total}',
                            style: AppTextStyles.caption.copyWith(
                              color: segment.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
