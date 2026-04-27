import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:provider/provider.dart';

class GlassBottomSheet extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final Widget? customContent;

  const GlassBottomSheet({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.confirmColor,
    this.customContent,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    Color? confirmColor,
    Widget? customContent,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      useRootNavigator: true,
      builder: (context) => GlassBottomSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmColor: confirmColor,
        customContent: customContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final potato = context.watch<PotatoModeProvider>();
    final hasBlur = potato.blurEffectsEnabled;

    final container = Container(
      decoration: BoxDecoration(
        color: hasBlur
            ? AppColors.glassBackgroundColor(context).withValues(alpha: 0.8)
            : AppColors.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: hasBlur
            ? Border(
                top: BorderSide(
                  color: AppColors.glassBorderColor(context),
                  width: 1.5,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.all(AppTokens.spacing24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              borderRadius: AppTokens.radiusFullAll,
            ),
          ),
          const SizedBox(height: AppTokens.spacing24),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : null,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTokens.spacing16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.mutedColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          if (customContent != null) ...[
            const SizedBox(height: AppTokens.spacing24),
            customContent!,
          ],
          const SizedBox(height: AppTokens.spacing32),
          Row(
            children: [
              if (onCancel != null || cancelLabel != null)
                Expanded(
                  child: TextButton(
                    onPressed: onCancel ?? () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : null,
                    ),
                    child: Text(cancelLabel ?? 'إلغاء'),
                  ),
                ),
              if ((onCancel != null || cancelLabel != null) &&
                  (onConfirm != null || confirmLabel != null))
                const SizedBox(width: AppTokens.spacing16),
              if (onConfirm != null || confirmLabel != null)
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor ?? AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(confirmLabel ?? 'تأكيد'),
                  ),
                ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );

    if (hasBlur) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: container,
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: container,
    );
  }
}
