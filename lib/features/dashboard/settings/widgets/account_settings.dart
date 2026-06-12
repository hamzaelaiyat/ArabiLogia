import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/widgets/solid_bottom_sheet.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/features/dashboard/settings/widgets/privacy_section.dart';

class AccountSettings extends StatelessWidget {
  const AccountSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('تعديل الملف الشخصي'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push(AppRoutes.profileEdit),
          ),
          const Divider(height: 1),
          const PrivacySection(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'حذف الحساب',
              style: TextStyle(color: Colors.red),
            ),
            trailing: const Icon(Icons.chevron_left, color: Colors.red),
            onTap: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    SolidBottomSheet.show(
      context: context,
      title: 'حذف الحساب',
      message: 'هل أنت متأكد من حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف الحساب',
      cancelLabel: 'إلغاء',
      confirmColor: Colors.red,
      onConfirm: () async {
        await context.read<AuthProvider>().signOut();
        if (context.mounted) {
          context.go(AppRoutes.login);
        }
      },
    );
  }
}
