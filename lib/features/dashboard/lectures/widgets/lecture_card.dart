import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class LectureCard extends StatelessWidget {
  final Map<String, dynamic> lecture;
  final VoidCallback? onTap;
  final Color categoryColor;

  const LectureCard({
    super.key,
    required this.lecture,
    this.onTap,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing8),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTokens.radius2xlAll,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spacing12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: AppTokens.radiusSmAll,
                  ),
                  child: Icon(
                    Icons.play_circle_outline,
                    color: categoryColor,
                    size: AppTokens.iconSizeLg,
                  ),
                ),
                const SizedBox(width: AppTokens.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lecture['title'] as String? ?? '',
                              style: Theme.of(context).textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lecture['quiz_id'] != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.quiz_outlined,
                              size: 14,
                              color: categoryColor,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if ((lecture['description'] as String? ?? '').isNotEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lecture['description'] as String? ?? '',
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left,
                  color: AppColors.mutedColor(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
