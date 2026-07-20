import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/widgets/dashboard_sidebar_nav_item.dart';
import 'package:arabilogia/features/dashboard/widgets/dashboard_sidebar_secondary_nav_item.dart';

class DashboardSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final bool isTeacher;
  final bool isAdmin;
  final VoidCallback onTeacherPanelTap;
  final VoidCallback onAboutTap;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;
  final String version;

  const DashboardSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.isTeacher,
    required this.isAdmin,
    required this.onTeacherPanelTap,
    required this.onAboutTap,
    required this.onTermsTap,
    required this.onPrivacyTap,
    required this.version,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppTokens.sidebarWidth,
      decoration: BoxDecoration(
        color: AppColors.background(context),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
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
                DashboardSidebarNavItem(
                  isSelected: selectedIndex == 0,
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'الرئيسية',
                  onTap: () => onItemTapped(0),
                ),
                DashboardSidebarNavItem(
                  isSelected: selectedIndex == 1,
                  icon: Icons.assignment_outlined,
                  selectedIcon: Icons.assignment,
                  label: 'المحاضرات',
                  onTap: () => onItemTapped(1),
                ),
                DashboardSidebarNavItem(
                  isSelected: selectedIndex == 2,
                  icon: Icons.leaderboard_outlined,
                  selectedIcon: Icons.leaderboard,
                  label: 'لوحة المتصدرين',
                  onTap: () => onItemTapped(2),
                ),
                DashboardSidebarNavItem(
                  isSelected: selectedIndex == 3,
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: 'الملف الشخصي',
                  onTap: () => onItemTapped(3),
                ),
                DashboardSidebarNavItem(
                  isSelected: selectedIndex == 4,
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'الإعدادات',
                  onTap: () => onItemTapped(4),
                ),
                if (isTeacher) ...[
                  const SizedBox(height: AppTokens.spacing16),
                  const Divider(),
                  DashboardSidebarNavItem(
                    isSelected: false,
                    icon: Icons.admin_panel_settings_outlined,
                    selectedIcon: Icons.admin_panel_settings,
                    label: isAdmin ? 'لوحة الإدارة' : 'لوحة المعلم',
                    onTap: onTeacherPanelTap,
                  ),
                ],
                const SizedBox(height: AppTokens.spacing16),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spacing16,
                    vertical: AppTokens.spacing8,
                  ),
                  child: Text(
                    'المعلومات والقانون',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.mutedColor(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DashboardSidebarSecondaryNavItem(
                  icon: Icons.info_outline,
                  label: 'عن عربيلوجيا',
                  onTap: onAboutTap,
                ),
                DashboardSidebarSecondaryNavItem(
                  icon: Icons.description_outlined,
                  label: 'الشروط والأحكام',
                  onTap: onTermsTap,
                ),
                DashboardSidebarSecondaryNavItem(
                  icon: Icons.privacy_tip_outlined,
                  label: 'سياسة الخصوصية',
                  onTap: onPrivacyTap,
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppTokens.spacing8),
            child: Text(
              version,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
