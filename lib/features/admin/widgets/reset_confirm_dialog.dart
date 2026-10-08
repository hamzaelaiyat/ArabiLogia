import 'package:flutter/material.dart';
import 'package:arabilogia/core/widgets/responsive_confirm.dart';

Future<bool> showResetPointsConfirmDialog(
  BuildContext context,
  String studentName,
  int currentBalance,
) async {
  return showResponsiveConfirmToast(
    context: context,
    message:
        'إعادة تعيين نقاط "$studentName" إلى صفر؟\n'
        'الرصيد الحالي: $currentBalance نقطة',
    confirmLabel: 'إعادة تعيين',
    confirmColor: Colors.red,
  );
}
