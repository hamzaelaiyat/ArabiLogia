import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_text_styles.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class ErrorState extends StatelessWidget {
  final String title;
  final String? detail;
  final VoidCallback? onRetry;
  final Widget? extra;

  const ErrorState({
    super.key,
    this.title = 'حدث خطأ ما',
    this.detail,
    this.onRetry,
    this.extra,
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
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: AppTokens.iconSizeXl,
                color: AppColors.error,
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
            if (detail != null) ...[
              const SizedBox(height: AppTokens.spacing4),
              Text(
                detail!,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.mutedColor(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (extra != null) ...[
              const SizedBox(height: AppTokens.spacing8),
              extra!,
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppTokens.spacing12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
