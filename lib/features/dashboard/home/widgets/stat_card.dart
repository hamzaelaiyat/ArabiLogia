import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class StatCard extends StatelessWidget {
  final String topTitle;
  final String value;
  final String bottomSubTitle;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.topTitle,
    required this.value,
    required this.bottomSubTitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = AppTokens.isDesktop(context);

    final cardBg = isDark ? AppColors.secondaryDark : AppColors.cardLightBg;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE5F3FF);

    return Semantics(
      label: '$topTitle $value $bottomSubTitle',
      button: onTap != null,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24.0),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 16.0 : 6.0,
              vertical: isDesktop ? 14.0 : 8.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    topTitle,
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.mutedDark : AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildValueWidget(value, isDark, isDesktop),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    bottomSubTitle,
                    style: TextStyle(
                      fontSize: isDesktop ? 13 : 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.mutedDark : AppColors.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValueWidget(String val, bool isDark, bool isDesktop) {
    final numFontSize = isDesktop ? 40.0 : 28.0;
    final percentFontSize = isDesktop ? 20.0 : 15.0;

    if (val.contains('%')) {
      final numberPart = val.replaceAll('%', '').trim();
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: numberPart,
              style: TextStyle(
                fontSize: numFontSize,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -1,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            TextSpan(
              text: '%',
              style: TextStyle(
                fontSize: percentFontSize,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      );
    }

    return Text(
      val,
      style: TextStyle(
        fontSize: numFontSize,
        fontWeight: FontWeight.w900,
        height: 1.1,
        letterSpacing: -1,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }
}
