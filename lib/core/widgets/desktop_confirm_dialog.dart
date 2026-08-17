import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class DesktopConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final Widget? customContent;

  const DesktopConfirmDialog({
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
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => DesktopConfirmDialog(
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spacing12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Text(
                  title,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.spacing8),
                Text(
                  message,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (customContent != null) ...[
                  const SizedBox(height: AppTokens.spacing12),
                  customContent!,
                ],
                const SizedBox(height: AppTokens.spacing12),
                Row(
                  children: [
                    if (cancelLabel != null)
                      Expanded(
                        child: TextButton(
                          onPressed: onCancel ?? () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                          ),
                          child: Text(cancelLabel!),
                        ),
                      ),
                    if (cancelLabel != null && confirmLabel != null)
                      const SizedBox(width: AppTokens.spacing8),
                    if (confirmLabel != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onConfirm ?? () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: confirmColor ?? colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          child: Text(confirmLabel!),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
