import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/providers/theme_provider.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final themeMode = themeProvider.themeModeOption;
    final isDark = themeProvider.isDarkMode;

    IconData getIcon() {
      switch (themeMode) {
        case ThemeModeOption.light:
          return Icons.light_mode_outlined;
        case ThemeModeOption.dark:
          return Icons.dark_mode_outlined;
        case ThemeModeOption.system:
          return Icons.settings_brightness_outlined;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTokens.spacing8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          getIcon(),
          color: isDark ? Colors.yellow : Colors.indigo.shade900,
        ),
        onPressed: () {
          // Toggle logic: If system, go to light. If light, go to dark. If dark, go to system?
          // More standard: Toggle between Light and Dark, or cycle through all three.
          // Let's cycle: System -> Light -> Dark -> System
          final current = themeProvider.themeModeOption;
          if (current == ThemeModeOption.system) {
            themeProvider.setThemeMode(ThemeModeOption.light);
          } else if (current == ThemeModeOption.light) {
            themeProvider.setThemeMode(ThemeModeOption.dark);
          } else {
            themeProvider.setThemeMode(ThemeModeOption.system);
          }

          // Snackbar removed - icon change provides sufficient visual feedback
        },
      ),
    );
  }

  String _getThemeName(ThemeModeOption option) {
    switch (option) {
      case ThemeModeOption.light:
        return 'الوضع النهاري';
      case ThemeModeOption.dark:
        return 'الوضع الليلي';
      case ThemeModeOption.system:
        return 'تلقائي (حسب النظام)';
    }
  }
}
