import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

enum BlockRowAction { edit, preview, delete }

class BlockRowWidget extends StatelessWidget {
  final int index;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final ValueChanged<BlockRowAction> onAction;

  const BlockRowWidget({
    super.key,
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: AppTokens.radiusMdAll),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacing4,
          vertical: AppTokens.spacing4,
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.spacing4),
                child: Icon(
                  Icons.drag_indicator,
                  color: AppColors.mutedColor(context),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppTokens.spacing8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: AppTokens.spacing4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: AppTokens.radiusFullAll,
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: AppTokens.fontSizeXs,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeSm,
                      color: AppColors.mutedColor(context),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<BlockRowAction>(
              tooltip: 'خيارات',
              onSelected: onAction,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: BlockRowAction.edit,
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: AppTokens.spacing4),
                      Text('تعديل'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: BlockRowAction.preview,
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 18),
                      SizedBox(width: AppTokens.spacing4),
                      Text('معاينة'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: BlockRowAction.delete,
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      SizedBox(width: AppTokens.spacing4),
                      Text('حذف', style: TextStyle(color: AppColors.error)),
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
