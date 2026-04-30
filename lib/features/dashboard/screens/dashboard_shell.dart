import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/features/legal/widgets/legal_bottom_sheet.dart';
import 'package:arabilogia/providers/exam_provider.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DashboardShell extends StatelessWidget {
  final Widget child;

  const DashboardShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.exams)) return 1;
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
        context.go(AppRoutes.exams);
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

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: potato.blurEffectsEnabled
          ? ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: _buildNavigationBar(context, selectedIndex),
              ),
            )
          : _buildNavigationBar(context, selectedIndex),
    );
  }

  Widget _buildNavigationBar(BuildContext context, int selectedIndex) {
    final potato = context.watch<PotatoModeProvider>();

    // In potato mode: SOLID background (no transparency)
    // Normal mode: Semi-transparent for glassmorphism effect
    final backgroundColor = potato.blurEffectsEnabled
        ? AppColors.background(context).withValues(alpha: 0.7)
        : AppColors.background(context);

    return NavigationBar(
      backgroundColor: backgroundColor,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _onItemTapped(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment),
          label: 'الامتحانات',
        ),
        NavigationDestination(
          icon: Icon(Icons.leaderboard_outlined),
          selectedIcon: Icon(Icons.leaderboard),
          label: 'المتصدرون',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'ملفي',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'الإعدادات',
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, int selectedIndex) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.03),
              AppColors.background(context),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: AppTokens.sidebarWidth,
              decoration: BoxDecoration(
                color: AppColors.background(context),
                border: Border(
                  left: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo-removedbg.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: AppTokens.spacing16),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTokens.spacing8,
                      ),
                      children: [
                        _buildNavItem(
                          context,
                          0,
                          Icons.home_outlined,
                          Icons.home,
                          'الرئيسية',
                        ),
                        _buildNavItem(
                          context,
                          1,
                          Icons.assignment_outlined,
                          Icons.assignment,
                          'الامتحانات',
                        ),
                        _buildNavItem(
                          context,
                          2,
                          Icons.leaderboard_outlined,
                          Icons.leaderboard,
                          'لوحة المتصدرين',
                        ),
                        _buildNavItem(
                          context,
                          3,
                          Icons.person_outline,
                          Icons.person,
                          'الملف الشخصي',
                        ),
                        _buildNavItem(
                          context,
                          4,
                          Icons.settings_outlined,
                          Icons.settings,
                          'الإعدادات',
                        ),
                        const SizedBox(height: AppTokens.spacing16),
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            if (!auth.isTeacher) return const SizedBox.shrink();
                            return Column(
                              children: [
                                const Divider(),
                                _buildNavItem(
                                  context,
                                  5,
                                  Icons.admin_panel_settings_outlined,
                                  Icons.admin_panel_settings,
                                  auth.isAdmin ? 'لوحة الإدارة' : 'لوحة المعلم',
                                  onTap: () =>
                                      context.push(AppRoutes.teacherPanel),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppTokens.spacing16),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.spacing16,
                            vertical: AppTokens.spacing8,
                          ),
                          child: Text(
                            'المعلومات والقانون',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.mutedColor(context),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        _buildSecondaryNavItem(
                          context,
                          Icons.info_outline,
                          'عن عربيلوجيا',
                          () => LegalBottomSheet.showAbout(context),
                        ),
                        _buildSecondaryNavItem(
                          context,
                          Icons.description_outlined,
                          'الشروط والأحكام',
                          () => LegalBottomSheet.showTerms(context),
                        ),
                        _buildSecondaryNavItem(
                          context,
                          Icons.privacy_tip_outlined,
                          'سياسة الخصوصية',
                          () => LegalBottomSheet.showPrivacy(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(AppTokens.spacing8),
                    child: Text(
                      'v0.0.1b',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    IconData selectedIcon,
    String label, {
    VoidCallback? onTap,
  }) {
    final isSelected =
        onTap == null && _calculateSelectedIndex(context) == index;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing8,
        vertical: AppTokens.spacing2,
      ),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: AppTokens.radiusMdAll,
        child: InkWell(
          onTap: onTap ?? () => _onItemTapped(context, index),
          borderRadius: AppTokens.radiusMdAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacing8,
              vertical: AppTokens.spacing6,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.mutedColor(context),
                  size: AppTokens.iconSizeMd,
                ),
                const SizedBox(width: AppTokens.spacing8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.foreground(context),
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryNavItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing8,
        vertical: AppTokens.spacing2,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTokens.radiusMdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTokens.radiusMdAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacing8,
              vertical: AppTokens.spacing6,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.mutedColor(context),
                  size: AppTokens.iconSizeXs,
                ),
                const SizedBox(width: AppTokens.spacing8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.foreground(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
