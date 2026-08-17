import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/desktop_confirm_dialog.dart';

Future<bool> showExitConfirmationDialog(BuildContext context) async {
  if (AppTokens.isDesktop(context)) {
    final result = await DesktopConfirmDialog.show<bool>(
      context: context,
      title: 'هل أنت متأكد؟',
      message: 'إذا خرجت الآن، ستفقد تقدمك في هذا الاختبار.',
      confirmLabel: 'خروج على أي حال',
      cancelLabel: 'إلغاء',
      confirmColor: AppColors.error,
      onConfirm: () => Navigator.pop(context, true),
    );
    return result ?? false;
  }

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('هل أنت متأكد؟'),
        content: const Text('إذا خرجت الآن، ستفقد تقدمك في هذا الاختبار.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('خروج على أي حال'),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
