import 'package:flutter/material.dart';
import 'package:arabilogia/features/legal/widgets/legal_bottom_sheet.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('عن التطبيق'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => LegalBottomSheet.showAbout(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('الشروط والأحكام'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => LegalBottomSheet.showTerms(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('سياسة الخصوصية'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => LegalBottomSheet.showPrivacy(context),
          ),
        ],
      ),
    );
  }
}
