import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeOption { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey);
      if (themeIndex != null && themeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeIndex];
      } else {
        _themeMode = ThemeMode.system;
      }
    } catch (e) {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, _themeMode.index);
    } catch (e) {
      // Ignore save errors
    }
  }

  ThemeModeOption get themeModeOption {
    switch (_themeMode) {
      case ThemeMode.light:
        return ThemeModeOption.light;
      case ThemeMode.dark:
        return ThemeModeOption.dark;
      case ThemeMode.system:
        return ThemeModeOption.system;
    }
  }

  void setThemeMode(ThemeModeOption option) {
    switch (option) {
      case ThemeModeOption.light:
        _themeMode = ThemeMode.light;
        break;
      case ThemeModeOption.dark:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeModeOption.system:
        _themeMode = ThemeMode.system;
        break;
    }
    _saveTheme();
    notifyListeners();
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  Color backgroundColor(BuildContext context) => AppColors.background(context);
  Color foregroundColor(BuildContext context) => AppColors.foreground(context);
  Color surfaceColor(BuildContext context) => AppColors.surface(context);
  Color mutedColor(BuildContext context) => AppColors.mutedColor(context);
}
