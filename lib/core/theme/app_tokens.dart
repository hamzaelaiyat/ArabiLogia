import 'package:flutter/material.dart';

class AppTokens {
  AppTokens._();

  static const String fontFamilyDisplay = 'ReadexPro';
  static const String fontFamilyBody = 'Rubik';

  static const double fontSizeXs = 11.0;
  static const double fontSizeSm = 12.0;
  static const double fontSizeMd = 14.0;
  static const double fontSizeLg = 16.0;
  static const double fontSizeXl = 18.0;
  static const double fontSize2xl = 22.0;
  static const double fontSize3xl = 24.0;
  static const double fontSize4xl = 28.0;
  static const double fontSize5xl = 32.0;
  static const double fontSize6xl = 45.0;
  static const double fontSize7xl = 57.0;

  static const double spacing2 = 4.0;
  static const double spacing4 = 8.0;
  static const double spacing6 = 12.0;
  static const double spacing8 = 16.0;
  static const double spacing10 = 20.0;
  static const double spacing12 = 24.0;
  static const double spacing16 = 32.0;
  static const double spacing20 = 40.0;
  static const double spacing24 = 48.0;
  static const double spacing32 = 64.0;

  static const double breakpointMobile = 768.0;
  static const double breakpointTablet = 1024.0;
  static const double breakpointDesktop = 1280.0;
  static const double contentMaxWidth = 1280.0;
  static const double dashboardPadding = 24.0;
  static const double dashboardPaddingMobile = 16.0;
  static const double sidebarWidth = 280.0;

  static const double touchTargetMin = 44.0;
  static const double iconSizeXs = 16.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 48.0;
  static const double iconSize2xl = 64.0;

  static const double buttonHeightSm = 40.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;
  static const double inputHeight = 52.0;

  static const double avatarSm = 32.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 64.0;
  static const double avatarXl = 96.0;

  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radius2xl = 24.0;
  static const double radius3xl = 32.0;
  static const double radiusFull = 999.0;

  static BorderRadius get radiusSmAll => BorderRadius.circular(radiusSm);
  static BorderRadius get radiusMdAll => BorderRadius.circular(radiusMd);
  static BorderRadius get radiusLgAll => BorderRadius.circular(radiusLg);
  static BorderRadius get radiusXlAll => BorderRadius.circular(radiusXl);
  static BorderRadius get radius2xlAll => BorderRadius.circular(radius2xl);
  static BorderRadius get radius3xlAll => BorderRadius.circular(radius3xl);
  static BorderRadius get radiusFullAll => BorderRadius.circular(radiusFull);

  static const double elevationNone = 0.0;
  static const double elevationSm = 1.0;
  static const double elevationMd = 2.0;
  static const double elevationLg = 4.0;
  static const double elevationXl = 8.0;

  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMd = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  static EdgeInsets get paddingXs => const EdgeInsets.all(spacing2);
  static EdgeInsets get paddingSm => const EdgeInsets.all(spacing4);
  static EdgeInsets get paddingMd => const EdgeInsets.all(spacing8);
  static EdgeInsets get paddingLg => const EdgeInsets.all(spacing12);
  static EdgeInsets get paddingXl => const EdgeInsets.all(spacing16);

  static EdgeInsets get paddingH4 =>
      const EdgeInsets.symmetric(horizontal: spacing4);
  static EdgeInsets get paddingH8 =>
      const EdgeInsets.symmetric(horizontal: spacing8);
  static EdgeInsets get paddingH12 =>
      const EdgeInsets.symmetric(horizontal: spacing12);
  static EdgeInsets get paddingH16 =>
      const EdgeInsets.symmetric(horizontal: spacing16);

  static EdgeInsets get paddingV4 =>
      const EdgeInsets.symmetric(vertical: spacing4);
  static EdgeInsets get paddingV8 =>
      const EdgeInsets.symmetric(vertical: spacing8);
  static EdgeInsets get paddingV12 =>
      const EdgeInsets.symmetric(vertical: spacing12);
  static EdgeInsets get paddingV16 =>
      const EdgeInsets.symmetric(vertical: spacing16);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < breakpointMobile;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointMobile &&
      MediaQuery.of(context).size.width < breakpointTablet;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointTablet;

  static const Color mobileBackground = Color(0xFFEBE7DF);
  static const Color mobileDarkBackground = Color(0xFF191B1D);
}
