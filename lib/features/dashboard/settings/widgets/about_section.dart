import 'package:flutter/material.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/services/update_service.dart';
import 'package:arabilogia/features/legal/widgets/legal_bottom_sheet.dart';

class AboutSection extends StatefulWidget {
  const AboutSection({super.key});

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  bool _checking = false;

  Future<void> _checkForUpdates() async {
    if (_checking) return;
    setState(() => _checking = true);
    // Ignore: use_build_context_synchronously
    final messenger = ScaffoldMessenger.of(context);
    final report = await UpdateService.checkForUpdatesInBackground(force: true);
    if (!mounted) return;
    setState(() => _checking = false);

    final String message;
    if (report.hasUpdate) {
      message = 'يتوفر تحديث ${report.latestVersion}';
    } else if (report.result == UpdateCheckResult.noUpdate) {
      message = 'أنت على آخر إصدار';
    } else {
      message = switch (report.failure) {
        UpdateCheckFailure.rateLimited =>
          'تم تجاوز حد الطلبات من GitHub، حاول بعد قليل',
        UpdateCheckFailure.network => 'تعذر الاتصال بالإنترنت',
        UpdateCheckFailure.serverError => 'GitHub لا يستجيب حالياً',
        UpdateCheckFailure.malformedResponse => 'تعذر قراءة بيانات التحديث',
        UpdateCheckFailure.noAsset => 'لا توجد نسخة تناسب جهازك',
        UpdateCheckFailure.none => 'تعذر التحقق من التحديثات',
      };
      debugPrint(
        '[UpdateService] manual check failed: ${report.failure} '
        'status=${report.httpStatus} detail=${report.detail}',
      );
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: TestKeys.settingsAbout,
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
          const Divider(height: 1),
          ListTile(
            leading: _checking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.system_update_alt),
            title: const Text('البحث عن تحديثات'),
            subtitle: const Text('تحقق من وجود إصدار أحدث الآن'),
            onTap: _checking ? null : _checkForUpdates,
          ),
        ],
      ),
    );
  }
}

