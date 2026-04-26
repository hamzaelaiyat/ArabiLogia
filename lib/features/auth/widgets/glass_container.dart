import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool isMobile;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 30.0,
    this.opacity = 0.2,
    this.color,
    this.padding,
    this.borderRadius,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = isMobile
        ? (borderRadius ?? BorderRadius.zero)
        : (borderRadius ?? BorderRadius.circular(32.0));

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppTokens.spacing12),
          decoration: BoxDecoration(
            color: color?.withValues(alpha: opacity) ??
                AppColors.glassBackgroundColor(context),
            borderRadius: effectiveRadius,
            border: Border.all(
              color: AppColors.glassBorderColor(context),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
