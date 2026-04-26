import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final double blurSigma;
  final double opacity;
  final PreferredSizeWidget? bottom;

  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
    this.blurSigma = 10.0,
    this.opacity = 0.7,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = backgroundColor ?? AppColors.background(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          color: effectiveColor.withValues(alpha: opacity),
          child: AppBar(
            title: title,
            actions: actions,
            leading: leading,
            automaticallyImplyLeading: automaticallyImplyLeading,
            centerTitle: centerTitle,
            elevation: elevation,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            bottom: bottom,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    final appBarHeight = kToolbarHeight + (bottom?.preferredSize.height ?? 0.0);
    return Size.fromHeight(appBarHeight);
  }
}
