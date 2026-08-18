import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_text_styles.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class AppMarkdownStyle {
  AppMarkdownStyle._();

  static MarkdownStyleSheet build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = AppColors.foreground(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final blockquoteBg = isDark
        ? AppColors.primary.withValues(alpha: 0.12)
        : AppColors.primary.withValues(alpha: 0.08);

    const borderSide = BorderSide(color: AppColors.primary, width: 4);

    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: AppTextStyles.bodyLg.copyWith(color: foreground, height: 1.6),
      h1: AppTextStyles.headingLg.copyWith(color: foreground),
      h2: AppTextStyles.headingMd.copyWith(color: foreground),
      h3: AppTextStyles.headingSm.copyWith(color: foreground),
      listBullet: AppTextStyles.bodyLg.copyWith(color: foreground),
      blockquote: AppTextStyles.bodyLg.copyWith(
        color: isDark ? const Color(0xFFF0F4F8) : const Color(0xFF2C353F),
        fontWeight: FontWeight.w500,
        height: 1.6,
      ),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      blockquoteDecoration: BoxDecoration(
        color: blockquoteBg,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          right: isRtl ? borderSide : BorderSide.none,
          left: isRtl ? BorderSide.none : borderSide,
        ),
      ),
      code: AppTextStyles.bodyMd.copyWith(
        fontFamily: 'monospace',
        color: isDark ? const Color(0xFFFFD599) : const Color(0xFFB35900),
        backgroundColor: isDark ? const Color(0xFF2C323B) : const Color(0xFFEFEFEF),
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark ? const Color(0xFF23272E) : const Color(0xFFF3F4F6),
        borderRadius: AppTokens.radiusSmAll,
      ),
    );
  }
}
