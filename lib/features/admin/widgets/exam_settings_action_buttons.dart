import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class ExamSettingsActionButtons extends StatelessWidget {
  final bool isPublished;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;
  final VoidCallback? onPreview;

  const ExamSettingsActionButtons({
    super.key,
    required this.isPublished,
    required this.onSaveDraft,
    required this.onPublish,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = AppColors.foreground(context);

    return Column(
      children: [
        if (onPreview != null) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPreview,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('معاينة الامتحان'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTokens.radiusLgAll,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSaveDraft,
                icon: const Icon(Icons.save_outlined),
                label: Text(isPublished ? 'حفظ التعديلات' : 'حفظ كمسودة'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: fgColor,
                  side: BorderSide(color: isDark ? Colors.white38 : Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTokens.radiusLgAll,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onPublish,
                icon: Icon(isPublished ? Icons.check_circle : Icons.publish),
                label: Text(isPublished ? 'تم النشر' : 'نشر الآن'),
                style: FilledButton.styleFrom(
                  backgroundColor: isPublished ? AppColors.success : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTokens.radiusLgAll,
                  ),
                  elevation: AppTokens.elevationNone,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}