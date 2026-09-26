import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

/// Shows a confirmation as a bottom sheet / dialog on mobile, or as a
/// SnackBar with a confirm action button on desktop.
///
/// Returns `true` if the user confirmed (tapped the action button), `false`
/// if they dismissed/cancelled.
Future<bool> showResponsiveConfirmToast({
  required BuildContext context,
  required String message,
  required String confirmLabel,
  Color? confirmColor,
  String? cancelLabel,
  Duration duration = const Duration(seconds: 4),
}) {
  final isDesktop = AppTokens.isDesktop(context);

  if (!isDesktop) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancelLabel ?? 'إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor ?? Colors.red,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return Future.value(false);

  // Modern non-blocking confirmation: the action runs immediately only when
  // the user taps the confirm button. The snackbar can be swiped away to
  // cancel, or it auto-dismisses without confirming.
  final completer = Completer<bool>();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: confirmLabel,
        textColor: confirmColor ?? Colors.white,
        onPressed: () {
          if (!completer.isCompleted) completer.complete(true);
        },
      ),
    ),
  );

  // Wait for the snackbar to close; if the action was pressed we already
  // completed. Otherwise resolve as cancelled.
  Future.delayed(duration + const Duration(milliseconds: 300), () {
    if (!completer.isCompleted) completer.complete(false);
  });

  return completer.future;
}
