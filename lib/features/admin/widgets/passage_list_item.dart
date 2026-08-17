import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class PassageListItem extends StatelessWidget {
  final Map<String, String> passage;
  final int index;
  final VoidCallback onDelete;

  const PassageListItem({
    super.key,
    required this.passage,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = AppColors.foreground(context);
    final imageUrl = passage['imageUrl'];
    final charCount = passage['content']?.length ?? 0;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final isImageOnly = hasImage && (passage['content']?.isEmpty ?? true);

    return Dismissible(
      key: ValueKey('passage_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) => onDelete(),
      confirmDismiss: (_) => _confirmDelete(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111315) : const Color(0xFFF0F4F7),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: hasImage
                    ? const Icon(Icons.image, color: AppColors.primary, size: 22)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: AppTokens.fontSizeSm,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passage['title'] ?? (isImageOnly ? 'صورة' : 'بدون عنوان'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppTokens.fontSizeMd,
                      color: fgColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isImageOnly ? Icons.image : Icons.text_fields,
                        size: 12,
                        color: AppColors.mutedColor(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isImageOnly ? 'صورة' : '$charCount حرف',
                        style: TextStyle(
                          color: AppColors.mutedColor(context),
                          fontSize: AppTokens.fontSizeXs,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                if (await _confirmDelete(context)) {
                  onDelete();
                }
              },
              icon: Icon(
                Icons.delete_outline,
                color: AppColors.error.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('حذف الفقرة'),
            content: const Text('هل أنت متأكد من حذف هذه الفقرة؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
