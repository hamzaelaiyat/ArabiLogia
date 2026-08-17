import 'package:flutter/material.dart';

Future<bool> showResetPointsConfirmDialog(
  BuildContext context,
  String studentName,
  int currentBalance,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إعادة تعيين النقاط'),
        content: Text(
          'هل أنت متأكد من إعادة تعيين نقاط "$studentName" إلى صفر؟\n\n'
          'الرصيد الحالي: $currentBalance نقطة\n'
          'سيتم تسجيل هذا الإجراء في السجل.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    ),
  );
  return confirmed ?? false;
}
