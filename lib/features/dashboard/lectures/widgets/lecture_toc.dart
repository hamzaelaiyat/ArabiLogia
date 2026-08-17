import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_text_styles.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class LectureTocEntry {
  final String label;
  final IconData icon;

  const LectureTocEntry({required this.label, required this.icon});
}

class LectureToc extends StatelessWidget {
  final List<LectureTocEntry> entries;
  final int activeIndex;
  final Color categoryColor;
  final ValueChanged<int> onEntryTap;

  const LectureToc({
    super.key,
    required this.entries,
    required this.activeIndex,
    required this.categoryColor,
    required this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing16),
      shape: RoundedRectangleBorder(borderRadius: AppTokens.radiusLgAll),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacing4,
                vertical: AppTokens.spacing2,
              ),
              child: Text(
                'محتويات المحاضرة',
                style: AppTextStyles.headingSm.copyWith(
                  color: AppColors.foreground(context),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacing4),
            ...List.generate(entries.length, (index) {
              final entry = entries[index];
              final isActive = index == activeIndex;
              return InkWell(
                onTap: () => onEntryTap(index),
                borderRadius: AppTokens.radiusSmAll,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spacing6,
                    vertical: AppTokens.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? categoryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: AppTokens.radiusSmAll,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        entry.icon,
                        size: AppTokens.iconSizeXs,
                        color: isActive
                            ? categoryColor
                            : AppColors.mutedColor(context),
                      ),
                      const SizedBox(width: AppTokens.spacing6),
                      Expanded(
                        child: Text(
                          entry.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: isActive
                                ? categoryColor
                                : AppColors.foreground(context),
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
