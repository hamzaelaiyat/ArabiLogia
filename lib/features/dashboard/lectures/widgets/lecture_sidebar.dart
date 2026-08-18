import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_text_styles.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/providers/contextual_sidebar_provider.dart';

class LectureSidebar extends StatelessWidget {
  final LectureSidebarData data;
  final double width;

  const LectureSidebar({
    super.key,
    required this.data,
    this.width = AppTokens.sidebarWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.background(context),
        border: Border(
          left: BorderSide(
            color: AppColors.mutedColor(context).withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section with Back Button & Lecture Category
          Container(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            decoration: BoxDecoration(
              color: data.categoryColor.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(
                  color: data.categoryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: data.categoryColor,
                        borderRadius: AppTokens.radiusFullAll,
                      ),
                      child: Text(
                        data.categoryName.isNotEmpty ? data.categoryName : 'المحاضرة',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'خروج من المحاضرة',
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: data.onBack,
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.spacing8),
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // TOC Header Label
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.spacing16,
              AppTokens.spacing16,
              AppTokens.spacing16,
              AppTokens.spacing8,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.format_list_bulleted_rounded,
                  size: 18,
                  color: data.categoryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'فهرس المحاضرة (TOC)',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // TOC List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacing8,
                vertical: AppTokens.spacing4,
              ),
              itemCount: data.tocEntries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final entry = data.tocEntries[index];
                final isActive = index == data.activeIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isActive
                        ? data.categoryColor.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: AppTokens.radiusMdAll,
                    border: Border.all(
                      color: isActive
                          ? data.categoryColor.withValues(alpha: 0.5)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spacing12,
                      vertical: 2,
                    ),
                    leading: Icon(
                      entry.icon,
                      size: 18,
                      color: isActive
                          ? data.categoryColor
                          : AppColors.mutedColor(context),
                    ),
                    title: Text(
                      entry.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive
                            ? data.categoryColor
                            : AppColors.foreground(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => data.onEntryTap(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
