import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class PassageHeader extends StatelessWidget {
  final VoidCallback onAddTap;

  const PassageHeader({
    super.key,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = AppColors.foreground(context);

    return Row(
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
            onPressed: onAddTap,
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            tooltip: 'إضافة فقرة',
            iconSize: 20,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }
}
