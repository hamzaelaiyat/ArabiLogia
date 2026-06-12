import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class SolidContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool isMobile;
  final Border? border;

  const SolidContainer({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.borderRadius,
    this.isMobile = false,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveRadius = isMobile
        ? (borderRadius ?? BorderRadius.zero)
        : (borderRadius ?? BorderRadius.circular(32.0));

    return Container(
      padding: padding ?? const EdgeInsets.all(AppTokens.spacing12),
      decoration: BoxDecoration(
        color: color ?? colorScheme.surface,
        borderRadius: effectiveRadius,
        border: border ??
            Border.all(
              color: colorScheme.outline.withValues(alpha: 0.12),
              width: 1,
            ),
      ),
      child: child,
    );
  }
}