import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_text_theme.dart';

class LightTheme {
  LightTheme._();

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: AppTokens.fontFamilyBody,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainerLight,
      onPrimaryContainer: AppColors.fgLight,
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.fgLight,
      secondaryContainer: AppColors.secondaryContainerLight,
      onSecondaryContainer: AppColors.fgLight,
      tertiary: AppColors.tertiaryContainerLight,
      onTertiary: AppColors.fgLight,
      surface: AppColors.bgLight,
      onSurface: AppColors.fgLight,
      error: AppColors.error,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.bgLight,
    textTheme: _buildTextTheme(Brightness.light),

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bgLight,
      foregroundColor: AppColors.fgLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.readexPro(
        fontSize: AppTokens.fontSizeXl,
        fontWeight: FontWeight.w600,
        color: AppColors.fgLight,
      ),
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: AppTokens.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: AppTokens.radius2xlAll),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, AppTokens.buttonHeightMd),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacing12,
          vertical: AppTokens.spacing10,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppTokens.radiusLgAll),
        elevation: AppTokens.elevationMd,
        textStyle: GoogleFonts.rubik(
          fontSize: AppTokens.fontSizeMd,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, AppTokens.buttonHeightMd),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacing12,
          vertical: AppTokens.spacing10,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppTokens.radiusLgAll),
        side: const BorderSide(color: AppColors.primary),
        textStyle: GoogleFonts.rubik(
          fontSize: AppTokens.fontSizeMd,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacing8,
          vertical: AppTokens.spacing4,
        ),
        textStyle: GoogleFonts.rubik(
          fontSize: AppTokens.fontSizeMd,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing12,
        vertical: AppTokens.spacing10,
      ),
      border: OutlineInputBorder(
        borderRadius: AppTokens.radiusXlAll,
        borderSide: const BorderSide(color: AppColors.mutedLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppTokens.radiusXlAll,
        borderSide: const BorderSide(color: AppColors.mutedLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppTokens.radiusXlAll,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppTokens.radiusXlAll,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppTokens.radiusXlAll,
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: GoogleFonts.rubik(
        fontSize: AppTokens.fontSizeMd,
        color: AppColors.mutedLight,
      ),
      hintStyle: GoogleFonts.rubik(
        fontSize: AppTokens.fontSizeMd,
        color: AppColors.mutedLight,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: AppTokens.elevationLg,
      shape: RoundedRectangleBorder(borderRadius: AppTokens.radius3xlAll),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.mutedLight,
      type: BottomNavigationBarType.fixed,
      elevation: AppTokens.elevationMd,
      selectedLabelStyle: GoogleFonts.rubik(
        fontSize: AppTokens.fontSizeXs,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.rubik(fontSize: AppTokens.fontSizeXs),
    ),

    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      selectedIconTheme: const IconThemeData(color: AppColors.primary),
      unselectedIconTheme: const IconThemeData(color: AppColors.mutedLight),
      selectedLabelTextStyle: GoogleFonts.rubik(
        fontSize: AppTokens.fontSizeXs,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
      ),
      unselectedLabelTextStyle: GoogleFonts.rubik(
        fontSize: AppTokens.fontSizeXs,
        color: AppColors.mutedLight,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.fgLight,
      contentTextStyle: GoogleFonts.rubik(
        fontSize: AppTokens.fontSizeMd,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppTokens.radiusMdAll),
      behavior: SnackBarBehavior.floating,
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.secondaryLight,
      thickness: 1,
      space: 0,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.secondaryLight,
      selectedColor: AppColors.primaryContainerLight,
      labelStyle: GoogleFonts.rubik(
        fontSize: AppTokens.fontSizeSm,
        color: AppColors.fgLight,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppTokens.radiusLgAll),
    ),
  );

  static TextTheme _buildTextTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final fg = isLight ? AppColors.fgLight : AppColors.fgDark;
    final muted = isLight ? AppColors.mutedLight : AppColors.mutedDark;

    return TextTheme(
      displayLarge: GoogleFonts.readexPro(
        fontSize: AppTokens.fontSize5xl,
        fontWeight: FontWeight.bold,
        color: fg,
      ),
      displayMedium: GoogleFonts.readexPro(
        fontSize: AppTokens.fontSize6xl,
        fontWeight: FontWeight.bold,
        color: fg,
      ),
      displaySmall: GoogleFonts.readexPro(
        fontSize: AppTokens.fontSize4xl,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
      headlineLarge: GoogleFonts.readexPro(
        fontSize: AppTokens.fontSize5xl,
        fontWeight: FontWeight.w700,
        color: fg,
      ),
      headlineMedium: GoogleFonts.readexPro(
        fontSize: AppTokens.fontSize4xl,
        fontWeight: FontWeight.bold,
        color: fg,
      ),
      headlineSmall: GoogleFonts.readexPro(
        fontSize: AppTokens.fontSize3xl,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
      titleLarge: GoogleFonts.readexPro(
        fontSize: AppTokens.fontSize2xl,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
      titleMedium: GoogleFonts.readexPro(
        fontSize: AppTokens.fontSizeXl,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
      titleSmall: GoogleFonts.rubik(
        fontSize: AppTokens.fontSizeSm,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
      bodyLarge: GoogleFonts.rubik(
        fontSize: AppTokens.fontSizeLg,
        fontWeight: FontWeight.normal,
        color: fg,
      ),
      bodyMedium: GoogleFonts.rubik(
        fontSize: AppTokens.fontSizeMd,
        fontWeight: FontWeight.normal,
        color: fg,
      ),
      bodySmall: GoogleFonts.rubik(
        fontSize: AppTokens.fontSizeXs,
        fontWeight: FontWeight.normal,
        color: muted,
      ),
      labelLarge: GoogleFonts.rubik(
        fontSize: AppTokens.fontSizeMd,
        fontWeight: FontWeight.w500,
        color: fg,
      ),
      labelMedium: GoogleFonts.rubik(
        fontSize: AppTokens.fontSizeSm,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
      labelSmall: GoogleFonts.rubik(
        fontSize: AppTokens.fontSizeXs,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
    );
  }
}
