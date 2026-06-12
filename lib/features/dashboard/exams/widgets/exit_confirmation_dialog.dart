import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

Future<bool> showExitConfirmationDialog(BuildContext context) async {
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
