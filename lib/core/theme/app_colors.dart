import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFEB8A00);
  static const Color primaryTo = Color(0xFFC26F00);
  static const Color accentLight = Color(0xFFEB5833);
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentSecondary = Color(0xFFFF8C42);

  static const Color bgLight = Color(
    0xFFE5F3FF,
  ); // Sidebar background & outer container #e5f3ff
  static const Color bgDark = Color(
    0xFF121417,
  ); // Dark outer background & sidebar

  static const Color dashboardContentBgLight = Color(
    0xFFFFFFFF,
  ); // Main content panel background #ffffff
  static const Color dashboardContentBgDark = Color(
    0xFF1A1D23,
  ); // Dark main widget card background

  static const Color authBgLight = Color(0xFFE5F3FF);
  static const Color authBgDark = Color(0xFF15181D);

  // Mobile app-wide background (used as the outer scaffold surface on mobile)
  static const Color mobileBackground = Color(0xFFEBE7DF);
  static const Color mobileDarkBackground = Color(0xFF191B1D);

  static const Color fgLight = Color(0xFF1A222B);
  static const Color fgDark = Color(0xFFEDF1F7);
  static const Color muted = Color(0xFF4D5660);
  static const Color mutedDark = Color(0xFF93A0B0);
  static const Color mutedLight = Color(0xFF6B7280);

  static const Color secondaryLight = Color(0xFFEDF2F8);
  static const Color secondaryDark = Color(
    0xFF23272E,
  ); // Card / input-surface color in dark mode

  // Consistent dark card/sheet surface (matches secondaryDark so every surface layers cleanly)
  static const Color cardDark = Color(0xFF23272E);
  // Light card surface (matches the historical 0xFFE5F3FF tint)
  static const Color cardLight = Color(0xFFE5F3FF);
  // Subtle dark hairline for dividers / outlines on dark surfaces
  static const Color hairlineDark = Color(0xFF323945);

  static const Color error = Color(0xFFFF3B30);
  static const Color errorDark = Color(0xFFD32F2F);
  static const Color success = Color(0xFF34C759);
  static const Color emerald = Color(0xFF30D158);
  static const Color warning = Color(0xFFFFCC00);
  static const Color blue = Color(0xFF2582FF);

  // Text colors (light mode)
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF475569);
  static const Color textLight = Color(0xFF64748B);

  // Card / surface backgrounds
  static const Color cardLightBg = Color(0xFFF9FCFF);

  // Skeleton / shimmer placeholder colors
  static const Color skeletonLight = Color(0xFFE0E0E0);
  static const Color skeletonLightHighlight = Color(0xFFF5F5F5);
  static const Color skeletonDark = Color(0xFF424242);
  static const Color skeletonDarkHighlight = Color(0xFF616161);

  static const Color examPass = Color(0xFF34C759);
  static const Color examFail = Color(0xFFFF3B30);
  static const Color examWarning = Color(0xFFFF9500);
  static const Color examUrgent = Color(0xFFC62828);

  static const Color surfaceGlass = Color(0x33FFFFFF);
  static const Color surfaceGlassDark = Color(0x1AFFFFFF);
  static const Color glowPrimary = Color(0x40EB8A00);

  static const Color primaryContainerLight = Color(0xFFF5E6D3);
  static const Color secondaryContainerLight = Color(0xFFFFE8E0);
  static const Color tertiaryContainerLight = Color(0xFFE8F5E9);

  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light ? bgLight : bgDark;
  }

  static Color dashboardContentBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? dashboardContentBgLight
        : dashboardContentBgDark;
  }

  static Color authBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? authBgLight
        : authBgDark;
  }

  static Color foreground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light ? fgLight : fgDark;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? secondaryLight
        : secondaryDark;
  }

  static Color skeleton(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? skeletonLight
        : skeletonDark;
  }

  static Color skeletonHighlight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? skeletonLightHighlight
        : skeletonDarkHighlight;
  }

  static Color mutedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light ? muted : mutedDark;
  }

  static Color primaryContainer(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? primaryContainerLight
        : primaryContainerLight.withValues(alpha: 0.3);
  }

  static Color glassBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.cardDark.withValues(alpha: 0.6);
  }

  static Color glassBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.hairlineDark.withValues(alpha: 0.8);
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
        return isDark
            ? Colors.blueGrey.shade300
            : Colors.grey.shade400; // Silver
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
