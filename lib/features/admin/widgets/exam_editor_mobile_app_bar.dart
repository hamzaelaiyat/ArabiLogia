import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class ExamEditorMobileAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;

  const ExamEditorMobileAppBar({
    super.key,
    required this.title,
    required this.onBack,
    required this.onSaveDraft,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: Icon(Icons.arrow_back, color: AppColors.foreground(context)),
        ),
        Expanded(
          child: Text(
            title.isEmpty ? 'اختبار جديد' : title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: onSaveDraft,
          icon: Icon(Icons.save_outlined, color: AppColors.mutedColor(context)),
          tooltip: 'حفظ كمسودة',
        ),
        IconButton(
          onPressed: onPublish,
          icon: const Icon(Icons.publish, color: AppColors.primary),
          tooltip: 'نشر',
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
