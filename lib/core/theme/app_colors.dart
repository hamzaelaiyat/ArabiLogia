import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFEB8A00);
  static const Color primaryTo = Color(0xFFC26F00);
  static const Color accentLight = Color(0xFFEB5833);

  static const Color bgLight = Color(0xFFF7FCFF);
  static const Color bgDark = Color(0xFF191B1D);

  static const Color fgLight = Color(0xFF1A222B);
  static const Color fgDark = Color(0xFFEAEFF5);
  static const Color muted = Color(0xFF4D5660);
  static const Color mutedLight = Color(0xFF4D5660);
  static const Color mutedDark = Color(0xFF91A0B1);

  static const Color secondaryLight = Color(0xFFEDF2F8);
  static const Color secondaryDark = Color(0xFF212325);

  static const Color error = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
  static const Color emerald = Color(0xFF30D158);
  static const Color warning = Color(0xFFFFCC00);

  static const Color surfaceGlass = Color(0x33FFFFFF);
  static const Color surfaceGlassDark = Color(0x1AFFFFFF);
  static const Color glowPrimary = Color(0x40EB8A00);

  static const Color primaryContainerLight = Color(0xFFF5E6D3);
  static const Color secondaryContainerLight = Color(0xFFFFE8E0);
  static const Color tertiaryContainerLight = Color(0xFFE8F5E9);

  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light ? bgLight : bgDark;
  }

  static Color foreground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light ? fgLight : fgDark;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? secondaryLight
        : secondaryDark;
  }

  static Color mutedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? mutedLight
        : mutedDark;
  }

  static Color primaryContainer(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? primaryContainerLight
        : primaryContainerLight.withValues(alpha: 0.3);
  }

  static Color glassBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.06);
  }

  static Color glassBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.15);
  }

  static Color authTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF3E2723)
        : fgDark;
  }

  static Color authLabelColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF6D4C41)
        : mutedDark;
  }

  static Color authHeaderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF5D4037)
        : fgDark;
  }

  static Color authSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF8D6E63)
        : mutedDark;
  }

  static Color chipSelectedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? primary.withValues(alpha: 0.15)
        : primary.withValues(alpha: 0.3);
  }

  static Color rankColor(int rank, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (rank) {
      case 1:
        return warning; // Gold
      case 2:
        return isDark ? Colors.blueGrey.shade300 : Colors.grey.shade400; // Silver
      case 3:
        return isDark ? Colors.brown.shade200 : Colors.brown.shade300; // Bronze
      default:
        return surface(context);
    }
  }

  static Color categoryColor(String name, BuildContext context) {
    switch (name) {
      case 'النحو':
        return const Color(0xFFE53935);
      case 'الصرف':
        return const Color(0xFF43A047);
      case 'الأدب':
        return const Color(0xFFFFB300);
      case 'الشعر':
        return const Color(0xFF8E24AA);
      case 'القراءة':
        return const Color(0xFFFB8C00);
      default:
        return primary;
    }
  }
}
