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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.article_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              'المقروءات',
              style: TextStyle(
                fontSize: AppTokens.fontSizeXl,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              tooltip: 'إضافة مقروء',
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spacing16),
        if (passages.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Text(
              'لم تقم بإضافة مقروءات بعد.\nاضغط + لإضافة مقروء جديد.',
              style: TextStyle(
                color: AppColors.mutedColor(context),
                fontSize: AppTokens.fontSizeSm,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...List.generate(
            passages.length,
            (idx) => _buildPassageItem(context, passages[idx], idx, isDark),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passage['title'] ?? 'بدون عنوان',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppTokens.fontSizeSm,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${passage['content']?.length ?? 0} حرف',
                  style: TextStyle(
                    color: AppColors.mutedColor(context),
                    fontSize: AppTokens.fontSizeXs,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => onDeletePassage(idx),
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مقروء جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'عنوان المقروء',
                  hintText: 'مثال: مقروء الوحدة الأولى',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentCtrl,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'نص المقروء',
                  hintText: 'أدخل النص الكامل...',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && contentCtrl.text.isNotEmpty) {
                onAddPassage(titleCtrl.text, contentCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
