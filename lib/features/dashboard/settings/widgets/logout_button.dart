import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/widgets/solid_bottom_sheet.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      key: TestKeys.settingsLogout,
      onPressed: () {
        SolidBottomSheet.show(
          context: context,
          title: 'تسجيل الخروج',
          message: 'هل أنت متأكد من تسجيل الخروج؟',
          confirmLabel: 'تسجيل الخروج',
          cancelLabel: 'إلغاء',
          confirmColor: Colors.red,
          onConfirm: () async {
            await context.read<AuthProvider>().signOut();
            if (context.mounted) {
              context.go(AppRoutes.login);
            }
          },
        );
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      icon: const Icon(Icons.logout),
      label: const Text('تسجيل الخروج'),
    );
  }
}
