import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/constants/app_version.dart';
import 'package:arabilogia/features/legal/widgets/legal_bottom_sheet.dart';
import 'package:arabilogia/features/dashboard/widgets/dashboard_bottom_nav_bar.dart';
import 'package:arabilogia/features/dashboard/widgets/dashboard_sidebar.dart';
import 'package:arabilogia/features/dashboard/exams/providers/exam_provider.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DashboardShell extends StatelessWidget {
  final Widget child;

  const DashboardShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.lectures) ||
        location.startsWith(AppRoutes.lecturePattern) ||
        location.startsWith(AppRoutes.exams)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.leaderboard)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    if (location.startsWith(AppRoutes.settings)) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    if (_calculateSelectedIndex(context) == index) return;

    final examProvider = context.read<ExamProvider>();
    if (examProvider.isExamInProgress) {
      _showExitConfirmation(context, index);
      return;
    }

    _navigate(context, index);
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.lectures);
        break;
      case 2:
        context.go(AppRoutes.leaderboard);
        break;
      case 3:
        context.go(AppRoutes.profile);
        break;
      case 4:
        context.go(AppRoutes.settings);
        break;
    }
  }

  void _showExitConfirmation(BuildContext context, int index) {
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.push(
      DialogRoute(
        context: context,
        builder: (dialogContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('هل أنت متأكد من الخروج؟'),
            content: const Text(
              'أنت حالياً في منتصف اختبار. إذا خرجت الآن، ستفقد جميع إجاباتك ولن يتم احتساب درجتك.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<ExamProvider>().endExam();
                  _navigate(context, index);
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('خروج وإلغاء الاختبار'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppTokens.isDesktop(context);
    final selectedIndex = _calculateSelectedIndex(context);

    if (isDesktop) {
      return _buildDesktopLayout(context, selectedIndex);
    } else {
      return _buildMobileLayout(context, selectedIndex);
    }
  }

  Widget _buildMobileLayout(BuildContext context, int selectedIndex) {
    final potato = context.watch<PotatoModeProvider>();
    final backgroundColor = potato.blurEffectsEnabled
        ? AppColors.background(context).withValues(alpha: 0.7)
        : AppColors.background(context);

    return Scaffold(
      key: TestKeys.dashboardShell,
      extendBody: true,
      body: child,
      bottomNavigationBar: potato.blurEffectsEnabled
          ? ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: DashboardBottomNavBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected:
                      (index) => _onItemTapped(context, index),
                  backgroundColor: backgroundColor,
                ),
              ),
            )
          : DashboardBottomNavBar(
              selectedIndex: selectedIndex,
              onDestinationSelected:
                  (index) => _onItemTapped(context, index),
              backgroundColor: backgroundColor,
            ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, int selectedIndex) {
    final auth = context.watch<AuthProvider>();
    final version = kIsWeb ? '' : AppVersion.displayVersion;

    return Scaffold(
      key: TestKeys.dashboardShell,
      body: Container(
        color: AppColors.background(context),
        child: Row(
          children: [
            DashboardSidebar(
              selectedIndex: selectedIndex,
              onItemTapped: (index) => _onItemTapped(context, index),
              isTeacher: auth.isTeacher,
              isAdmin: auth.isAdmin,
              onTeacherPanelTap: () => context.push(AppRoutes.teacherPanel),
              onAboutTap: () => LegalBottomSheet.showAbout(context),
              onTermsTap: () => LegalBottomSheet.showTerms(context),
              onPrivacyTap: () => LegalBottomSheet.showPrivacy(context),
              version: version,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
