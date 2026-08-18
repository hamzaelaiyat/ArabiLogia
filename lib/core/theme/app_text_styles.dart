import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLg = TextStyle(
    fontFamily: AppTokens.fontFamilyDisplay,
    fontSize: AppTokens.fontSize6xl,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle displayMd = TextStyle(
    fontFamily: AppTokens.fontFamilyDisplay,
    fontSize: AppTokens.fontSize5xl,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle headingLg = TextStyle(
    fontFamily: AppTokens.fontFamilyDisplay,
    fontSize: AppTokens.fontSize4xl,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle headingMd = TextStyle(
    fontFamily: AppTokens.fontFamilyDisplay,
    fontSize: AppTokens.fontSize3xl,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle headingSm = TextStyle(
    fontFamily: AppTokens.fontFamilyDisplay,
    fontSize: AppTokens.fontSizeXl,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: AppTokens.fontFamilyBody,
    fontSize: AppTokens.fontSizeLg,
    height: 1.7,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: AppTokens.fontFamilyBody,
    fontSize: AppTokens.fontSizeMd,
    height: 1.6,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: AppTokens.fontFamilyBody,
    fontSize: AppTokens.fontSizeSm,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: AppTokens.fontFamilyBody,
    fontSize: AppTokens.fontSizeXs,
    height: 1.4,
  );
}
