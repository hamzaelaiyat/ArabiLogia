import 'package:flutter/material.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:arabilogia/core/widgets/responsive_app_bar_title.dart';
import 'package:arabilogia/core/widgets/section_title.dart';
import 'package:arabilogia/features/dashboard/settings/widgets/theme_selector.dart';
import 'package:arabilogia/features/dashboard/settings/widgets/performance_mode_selector.dart';
import 'package:arabilogia/features/dashboard/settings/widgets/account_settings.dart';
import 'package:arabilogia/features/dashboard/settings/widgets/notification_settings.dart';
import 'package:arabilogia/features/dashboard/settings/widgets/exam_offline_settings.dart';
import 'package:arabilogia/features/dashboard/settings/widgets/about_section.dart';
import 'package:arabilogia/features/dashboard/settings/widgets/logout_button.dart';
import 'package:arabilogia/features/dashboard/settings/widgets/report_problem_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: TestKeys.settingsScreen,
        appBar: const GlassAppBar(title: ResponsiveAppBarTitle('الإعدادات')),
        body: ListView(
          padding: const EdgeInsets.all(AppTokens.spacing8),
          clipBehavior: Clip.none,
          children: const [
            SectionTitle(title: 'المظهر'),
            ThemeSelector(),
            SizedBox(height: AppTokens.spacing16),
            SectionTitle(title: 'وضع الأداء'),
            PerformanceModeSelector(),
            SizedBox(height: AppTokens.spacing16),
            SectionTitle(title: 'الحساب'),
            AccountSettings(),
            SizedBox(height: AppTokens.spacing16),
            SectionTitle(title: 'الإشعارات'),
            NotificationSettings(),
            SizedBox(height: AppTokens.spacing16),
            SectionTitle(title: 'المحاضرات والتحميل'),
            ExamOfflineSettings(),
            SizedBox(height: AppTokens.spacing16),
            SectionTitle(title: 'حول'),
            AboutSection(),
            SizedBox(height: AppTokens.spacing16),
            SectionTitle(title: 'الدعم والمساعدة'),
            ReportProblemSection(),
            SizedBox(height: AppTokens.spacing24),
            LogoutButton(),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
