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
    // Map shell index (0: Home, 1: Lectures, 2: Leaderboard, 3: Profile, 4: Settings) to 4-item bottom bar
    int navIndex = selectedIndex;
    if (navIndex >= 3) {
      navIndex = selectedIndex == 4 ? 3 : 0;
    }

    return NavigationBar(
      backgroundColor: backgroundColor,
      selectedIndex: navIndex,
      onDestinationSelected: (index) {
        // Map 4 bottom bar items back to shell indices (0: Home, 1: Lectures, 2: Leaderboard, 4: Settings)
        int targetIndex = index;
        if (index == 3) targetIndex = 4;
        onDestinationSelected(targetIndex);
      },
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
          key: TestKeys.navSettings,
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'الإعدادات',
        ),
      ],
    );
  }
}
