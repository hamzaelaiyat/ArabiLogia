import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/widgets/section_title.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:arabilogia/core/widgets/responsive_confirm.dart';
import 'package:arabilogia/providers/theme_provider.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:arabilogia/features/admin/widgets/exam_defaults_section.dart';
import 'package:arabilogia/features/dashboard/settings/widgets/performance_mode_selector.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class TeacherSettingsScreen extends StatelessWidget {
  const TeacherSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: GlassAppBar(
          title: const Text('إعدادات المعلم'),
          forceShowOnDesktop: true,
          actions: const [],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.teacherPanel);
              }
            },
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              children: [
                const SectionTitle(title: 'المظهر'),
                _buildThemeSelector(context),
                const SizedBox(height: AppTokens.spacing16),
                const SectionTitle(title: 'وضع الأداء'),
                const PerformanceModeSelector(),
                const SizedBox(height: AppTokens.spacing16),
                const SectionTitle(title: 'إعدادات الامتحان الافتراضية'),
                const ExamDefaultsSection(),
                const SizedBox(height: AppTokens.spacing16),
                const SectionTitle(title: 'الحساب'),
                _buildLogoutButton(context),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.spacing4),
          child: SegmentedButton<ThemeModeOption>(
            segments: const [
              ButtonSegment<ThemeModeOption>(
                value: ThemeModeOption.light,
                label: Text('فاتح'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment<ThemeModeOption>(
                value: ThemeModeOption.dark,
                label: Text('داكن'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
              ButtonSegment<ThemeModeOption>(
                value: ThemeModeOption.system,
                label: Text('تلقائي'),
                icon: Icon(Icons.settings_brightness_outlined),
              ),
            ],
            selected: {themeProvider.themeModeOption},
            onSelectionChanged: (Set<ThemeModeOption> selection) {
              themeProvider.setThemeMode(selection.first);
            },
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
        trailing: const Icon(Icons.chevron_left, color: Colors.red),
        onTap: () => _showSignOutDialog(context),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showResponsiveConfirmToast(
      context: context,
      message: 'هل أنت متأكد من تسجيل الخروج؟',
      confirmLabel: 'تسجيل الخروج',
      confirmColor: Colors.red,
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        await context.read<AuthProvider>().signOut();
        if (context.mounted) {
          context.go(AppRoutes.login);
        }
      }
    });
  }
}
