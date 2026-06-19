import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class AppTextTheme {
  AppTextTheme._();

  static TextTheme get light => TextTheme(
    displayLarge: TextStyle(
      fontFamily: AppTokens.fontFamilyDisplay,
      fontSize: AppTokens.fontSize5xl,
      fontWeight: FontWeight.bold,
      color: AppColors.fgLight,
    ),
    displayMedium: TextStyle(
      fontFamily: AppTokens.fontFamilyDisplay,
      fontSize: AppTokens.fontSize6xl,
      fontWeight: FontWeight.bold,
      color: AppColors.fgLight,
    ),
    displaySmall: TextStyle(
      fontFamily: AppTokens.fontFamilyDisplay,
      fontSize: AppTokens.fontSize4xl,
      fontWeight: FontWeight.w600,
      color: AppColors.fgLight,
    ),
    headlineLarge: TextStyle(
      fontFamily: AppTokens.fontFamilyDisplay,
      fontSize: AppTokens.fontSize5xl,
      fontWeight: FontWeight.w700,
      color: AppColors.fgLight,
    ),
    headlineMedium: TextStyle(
      fontFamily: AppTokens.fontFamilyDisplay,
      fontSize: AppTokens.fontSize4xl,
      fontWeight: FontWeight.bold,
      color: AppColors.fgLight,
    ),
    headlineSmall: TextStyle(
      fontFamily: AppTokens.fontFamilyDisplay,
      fontSize: AppTokens.fontSize3xl,
      fontWeight: FontWeight.w600,
      color: AppColors.fgLight,
    ),
    titleLarge: TextStyle(
      fontFamily: AppTokens.fontFamilyDisplay,
      fontSize: AppTokens.fontSize2xl,
      fontWeight: FontWeight.w600,
      color: AppColors.fgLight,
    ),
    titleMedium: TextStyle(
      fontFamily: AppTokens.fontFamilyDisplay,
      fontSize: AppTokens.fontSizeXl,
      fontWeight: FontWeight.w600,
      color: AppColors.fgLight,
    ),
    titleSmall: TextStyle(
      fontFamily: AppTokens.fontFamilyBody,
      fontSize: AppTokens.fontSizeSm,
      fontWeight: FontWeight.w600,
      color: AppColors.fgLight,
    ),
    bodyLarge: TextStyle(
      fontFamily: AppTokens.fontFamilyBody,
      fontSize: AppTokens.fontSizeLg,
      fontWeight: FontWeight.normal,
      color: AppColors.fgLight,
    ),
    bodyMedium: TextStyle(
      fontFamily: AppTokens.fontFamilyBody,
      fontSize: AppTokens.fontSizeMd,
      fontWeight: FontWeight.normal,
      color: AppColors.fgLight,
    ),
    bodySmall: TextStyle(
      fontFamily: AppTokens.fontFamilyBody,
      fontSize: AppTokens.fontSizeXs,
      fontWeight: FontWeight.normal,
      color: AppColors.mutedLight,
    ),
    labelLarge: TextStyle(
      fontFamily: AppTokens.fontFamilyBody,
      fontSize: AppTokens.fontSizeMd,
      fontWeight: FontWeight.w500,
      color: AppColors.fgLight,
    ),
    labelMedium: TextStyle(
      fontFamily: AppTokens.fontFamilyBody,
      fontSize: AppTokens.fontSizeSm,
      fontWeight: FontWeight.w500,
      color: AppColors.mutedLight,
    ),
    labelSmall: TextStyle(
      fontFamily: AppTokens.fontFamilyBody,
      fontSize: AppTokens.fontSizeXs,
      fontWeight: FontWeight.w500,
      color: AppColors.mutedLight,
    ),
  );

  static TextTheme get dark => TextTheme(
    displayLarge: TextStyle(
      fontFamily: AppTokens.fontFamilyDisplay,
      fontSize: AppTokens.fontSize5xl,
      fontWeight: FontWeight.bold,
      color: AppColors.fgDark,
    ),
    displayMedium: TextStyle(
      fontFamily: AppTokens.fontFamilyDisplay,
      fontSize: AppTokens.fontSize6xl,
      fontWeight: FontWeight.bold,
      color: AppColors.fgDark,
    ),
    displaySmall: TextStyle(
      fontFamily: AppTokens.fontFamilyDisplay,
      fontSize: AppTokens.fontSize4xl,
      fontWeight: FontWeight.w600,
      color: AppColors.fgDark,
    ),
    headlineLarge: TextStyle(
      fontFamily: AppTokens.fontFamilyDisplay,
      fontSize: AppTokens.fontSize5xl,
      fontWeight: FontWeight.w700,
      color: AppColors.fgDark,
    ),
    headlineMedium: TextStyle(
      fontFamily: AppTokens.fontFamilyDisplay,
      fontSize: AppTokens.fontSize4xl,
      fontWeight: FontWeight.bold,
      color: AppColors.fgDark,
    ),
    headlineSmall: TextStyle(
      fontFamily: AppTokens.fontFamilyDisplay,
      fontSize: AppTokens.fontSize3xl,
      fontWeight: FontWeight.w600,
      color: AppColors.fgDark,
    ),
    titleLarge: TextStyle(
      fontFamily: AppTokens.fontFamilyDisplay,
      fontSize: AppTokens.fontSize2xl,
      fontWeight: FontWeight.w600,
      color: AppColors.fgDark,
    ),
    titleMedium: TextStyle(
      fontFamily: AppTokens.fontFamilyDisplay,
      fontSize: AppTokens.fontSizeXl,
      fontWeight: FontWeight.w600,
      color: AppColors.fgDark,
    ),
    titleSmall: TextStyle(
      fontFamily: AppTokens.fontFamilyBody,
      fontSize: AppTokens.fontSizeSm,
      fontWeight: FontWeight.w600,
      color: AppColors.fgDark,
    ),
    bodyLarge: TextStyle(
      fontFamily: AppTokens.fontFamilyBody,
      fontSize: AppTokens.fontSizeLg,
      fontWeight: FontWeight.normal,
      color: AppColors.fgDark,
    ),
    bodyMedium: TextStyle(
      fontFamily: AppTokens.fontFamilyBody,
      fontSize: AppTokens.fontSizeMd,
      fontWeight: FontWeight.normal,
      color: AppColors.fgDark,
    ),
    bodySmall: TextStyle(
      fontFamily: AppTokens.fontFamilyBody,
      fontSize: AppTokens.fontSizeXs,
      fontWeight: FontWeight.normal,
      color: AppColors.mutedDark,
    ),
    labelLarge: TextStyle(
      fontFamily: AppTokens.fontFamilyBody,
      fontSize: AppTokens.fontSizeMd,
      fontWeight: FontWeight.w500,
      color: AppColors.fgDark,
    ),
    labelMedium: TextStyle(
      fontFamily: AppTokens.fontFamilyBody,
      fontSize: AppTokens.fontSizeSm,
      fontWeight: FontWeight.w500,
      color: AppColors.mutedDark,
    ),
    labelSmall: TextStyle(
      fontFamily: AppTokens.fontFamilyBody,
      fontSize: AppTokens.fontSizeXs,
      fontWeight: FontWeight.w500,
      color: AppColors.mutedDark,
    ),
  );
}
