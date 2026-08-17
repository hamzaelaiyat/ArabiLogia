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

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty || _total == 0) return const SizedBox.shrink();

    final percentageInt = ((_completed / _total) * 100).round();

    return Card(
      elevation: 3,
      shadowColor: categoryColor.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: AppTokens.radiusLgAll),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تقدمك في المحاضرة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '$percentageInt%',
                  style: TextStyle(
                    color: categoryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: AppTokens.fontSizeLg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacing8),
            SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (final segment in segments)
                    if (segment.total > 0)
                      Expanded(
                        flex: segment.total,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ColoredBox(
                                  color:
                                      segment.color.withValues(alpha: 0.15),
                                ),
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: FractionallySizedBox(
                                    widthFactor: (segment.completed /
                                            segment.total)
                                        .clamp(0.0, 1.0),
                                    child: ColoredBox(color: segment.color),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spacing8),
            Wrap(
              spacing: AppTokens.spacing8,
              runSpacing: AppTokens.spacing4,
              children: [
                for (final segment in segments)
                  if (segment.total > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          segment.icon,
                          size: AppTokens.iconSizeXs,
                          color: segment.color,
                        ),
                        const SizedBox(width: AppTokens.spacing2),
                        Text(
                          '${segment.label} ${segment.completed}/${segment.total}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.mutedColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
