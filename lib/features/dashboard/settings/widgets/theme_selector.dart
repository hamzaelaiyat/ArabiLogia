import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/providers/theme_provider.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
    return Padding(
      key: TestKeys.settingsThemeSelector,
      padding: const EdgeInsets.symmetric(vertical: 4),
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
}
