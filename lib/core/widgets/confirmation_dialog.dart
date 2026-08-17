import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/desktop_confirm_dialog.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;
  final VoidCallback? onConfirm;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmLabel,
    this.cancelLabel = 'إلغاء',
    this.confirmColor,
    this.onConfirm,
  });

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmLabel,
    String cancelLabel = 'إلغاء',
    Color? confirmColor,
  }) async {
    if (AppTokens.isDesktop(context)) {
      final result = await DesktopConfirmDialog.show<bool>(
        context: context,
        title: title,
        message: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
        onConfirm: () => Navigator.pop(context, true),
      );
      return result ?? false;
    }

    return await showDialog<bool>(
          context: context,
          builder: (ctx) => ConfirmationDialog(
            title: title,
            content: content,
            confirmLabel: confirmLabel,
            cancelLabel: cancelLabel,
            confirmColor: confirmColor,
            onConfirm: () => Navigator.pop(ctx, true),
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: onConfirm ?? () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}
