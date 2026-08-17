import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class PassageEmptyState extends StatelessWidget {
  const PassageEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = AppColors.foreground(context);

    return Container(
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
    );
  }
}
