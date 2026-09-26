import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/features/dashboard/settings/widgets/privacy_section.dart';

class AccountSettings extends StatelessWidget {
  const AccountSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: TestKeys.settingsAccount,
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
        ],
      ),
    );
  }
}
