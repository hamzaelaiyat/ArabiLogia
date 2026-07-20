import 'package:flutter/material.dart';
import 'package:arabilogia/core/constants/test_keys.dart';

class DashboardBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Color backgroundColor;

  const DashboardBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: backgroundColor,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(
          key: TestKeys.navHome,
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          key: TestKeys.navLectures,
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment),
          label: 'المحاضرات',
        ),
        NavigationDestination(
          key: TestKeys.navLeaderboard,
          icon: Icon(Icons.leaderboard_outlined),
          selectedIcon: Icon(Icons.leaderboard),
          label: 'المتصدرون',
        ),
        NavigationDestination(
          key: TestKeys.navProfile,
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'ملفي',
        ),
        NavigationDestination(
          key: TestKeys.navSettings,
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'الإعدادات',
        ),
      ],
    );
  }
}
