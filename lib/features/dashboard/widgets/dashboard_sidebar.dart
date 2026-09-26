import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/widgets/dashboard_sidebar_nav_item.dart';
import 'package:arabilogia/features/dashboard/widgets/sidebar_legal_accordion.dart';

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
  final bool isPinned;
  final VoidCallback? onTogglePin;
  final double width;

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
    this.isPinned = true,
    this.onTogglePin,
    this.width = AppTokens.sidebarWidth,
  });

  @override
  Widget build(BuildContext context) {
    final showLabels = width >= 140;

    return Container(
      width: width,
      decoration: BoxDecoration(color: AppColors.background(context)),
      child: Column(
        children: [
          const SizedBox(height: AppTokens.spacing16),

          // Header: Single Logo centered with Pin Icon on the side
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacing8),
            child: SizedBox(
              height: showLabels ? 64 : 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/logo-removedbg.png',
                      width: showLabels ? 64 : 44,
                      height: showLabels ? 64 : 44,
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (showLabels && onTogglePin != null)
                    Positioned(
                      left: Directionality.of(context) == TextDirection.rtl
                          ? null
                          : 0,
                      right: Directionality.of(context) == TextDirection.rtl
                          ? 0
                          : null,
                      child: IconButton(
                        icon: Icon(
                          isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          color: isPinned
                              ? Theme.of(context).colorScheme.primary
                              : AppColors.mutedColor(context),
                          size: 20,
                        ),
                        tooltip: isPinned
                            ? 'إلغاء تثبيت الشريط الجانبي'
                            : 'تثبيت الشريط الجانبي',
                        onPressed: onTogglePin,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacing16),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.spacing8),
              children: [
                DashboardSidebarNavItem(
                  isSelected: selectedIndex == 0,
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: showLabels ? 'الرئيسية' : '',
                  onTap: () => onItemTapped(0),
                ),
                DashboardSidebarNavItem(
                  isSelected: selectedIndex == 1,
                  icon: Icons.assignment_outlined,
                  selectedIcon: Icons.assignment,
                  label: showLabels ? 'المحاضرات' : '',
                  onTap: () => onItemTapped(1),
                ),
                DashboardSidebarNavItem(
                  isSelected: selectedIndex == 2,
                  icon: Icons.leaderboard_outlined,
                  selectedIcon: Icons.leaderboard,
                  label: showLabels ? 'لوحة المتصدرين' : '',
                  onTap: () => onItemTapped(2),
                ),
                DashboardSidebarNavItem(
                  isSelected: selectedIndex == 4,
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: showLabels ? 'الإعدادات' : '',
                  onTap: () => onItemTapped(4),
                ),
                if (isTeacher) ...[
                  const SizedBox(height: AppTokens.spacing20),
                  DashboardSidebarNavItem(
                    isSelected: false,
                    icon: Icons.admin_panel_settings_outlined,
                    selectedIcon: Icons.admin_panel_settings,
                    label: showLabels
                        ? (isAdmin ? 'لوحة الإدارة' : 'لوحة المعلم')
                        : '',
                    onTap: onTeacherPanelTap,
                  ),
                ],
              ],
            ),
          ),

          // Bottom Accordion Section for "المنصة والقانون"
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacing12,
              vertical: AppTokens.spacing4,
            ),
            child: SidebarLegalAccordion(
              showLabels: showLabels,
              onAboutTap: onAboutTap,
              onTermsTap: onTermsTap,
              onPrivacyTap: onPrivacyTap,
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(
              left: AppTokens.spacing12,
              right: AppTokens.spacing12,
              bottom: AppTokens.spacing8,
            ),
            child: Text(
              showLabels ? version : '',
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
