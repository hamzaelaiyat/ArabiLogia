import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class PassageManager extends StatelessWidget {
  final List<Map<String, String>> passages;
  final Function(String, String) onAddPassage;
  final Function(int) onDeletePassage;

  const PassageManager({
    super.key,
    required this.passages,
    required this.onAddPassage,
    required this.onDeletePassage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = AppColors.foreground(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.article_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'الفقرات',
              style: TextStyle(
                fontSize: AppTokens.fontSizeXl,
                fontWeight: FontWeight.bold,
                fontFamily: AppTokens.fontFamilyDisplay,
                color: fgColor,
              ),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => _showAddDialog(context, isDark),
                icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                tooltip: 'إضافة فقرة',
                iconSize: 20,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spacing16),
        if (passages.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTokens.spacing20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111315) : const Color(0xFFF0F4F7),
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 48,
                  color: AppColors.mutedColor(context).withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'لم تقم بإضافة فقرات بعد',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                    fontSize: AppTokens.fontSizeMd,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اضغط + لإضافة فقرة جديدة',
                  style: TextStyle(
                    color: AppColors.mutedColor(context),
                    fontSize: AppTokens.fontSizeSm,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: passages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) => _buildPassageItem(context, passages[idx], idx, isDark),
          ),
      ],
    );
  }

  Widget _buildPassageItem(
    BuildContext context,
    Map<String, String> passage,
    int idx,
    bool isDark,
  ) {
    final fgColor = AppColors.foreground(context);
    final charCount = passage['content']?.length ?? 0;

    return Dismissible(
      key: ValueKey('passage_$idx'),
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
      onDismissed: (_) => onDeletePassage(idx),
      confirmDismiss: (_) => _confirmDelete(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111315) : const Color(0xFFF0F4F7),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${idx + 1}',
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
                    passage['title'] ?? 'بدون عنوان',
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
                        Icons.text_fields,
                        size: 12,
                        color: AppColors.mutedColor(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$charCount حرف',
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
                  onDeletePassage(idx);
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

  void _showAddDialog(BuildContext context, bool isDark) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final fgColor = AppColors.foreground(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232527) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'إضافة فقرة جديدة',
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeXl,
                      fontWeight: FontWeight.bold,
                      color: fgColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close, color: fgColor),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: TextStyle(color: fgColor),
                      decoration: InputDecoration(
                        labelText: 'عنوان الفقرة',
                        hintText: 'مثال: فقرة الوحدة الأولى',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF111315) : const Color(0xFFF0F4F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.title, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentCtrl,
                      maxLines: 12,
                      style: TextStyle(color: fgColor, height: 1.6),
                      decoration: InputDecoration(
                        labelText: 'نص الفقرة',
                        hintText: 'أدخل النص الكامل للفقرة...',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF111315) : const Color(0xFFF0F4F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).padding.bottom + 20,
                top: 16,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232527) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (titleCtrl.text.isNotEmpty && contentCtrl.text.isNotEmpty) {
                          onAddPassage(titleCtrl.text, contentCtrl.text);
                          Navigator.pop(ctx);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إضافة'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
