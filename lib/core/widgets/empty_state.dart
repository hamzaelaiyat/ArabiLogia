import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_text_styles.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTokens.paddingXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppTokens.avatarXl,
              height: AppTokens.avatarXl,
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppTokens.iconSizeXl,
                color: AppColors.mutedColor(context),
              ),
            ),
            const SizedBox(height: AppTokens.spacing8),
            Text(
              title,
              style: AppTextStyles.headingSm.copyWith(
                color: AppColors.foreground(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spacing4),
            Text(
              message,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.mutedColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppTokens.spacing12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
