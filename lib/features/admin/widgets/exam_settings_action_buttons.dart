import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class ExamSettingsActionButtons extends StatelessWidget {
  final bool isPublished;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;

  const ExamSettingsActionButtons({
    super.key,
    required this.isPublished,
    required this.onSaveDraft,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = AppColors.foreground(context);

    return Row(
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
    );
  }
}