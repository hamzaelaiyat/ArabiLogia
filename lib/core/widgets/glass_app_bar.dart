import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:provider/provider.dart';

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
  final bool forceShowOnDesktop;

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
    this.forceShowOnDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final showDesktopAppBar = forceShowOnDesktop || leading != null || (automaticallyImplyLeading && canPop);

    if (!AppTokens.isMobile(context) && !showDesktopAppBar) {
      if (bottom != null) {
        final effectiveColor = backgroundColor ?? AppColors.background(context);
        return Container(
          height: bottom!.preferredSize.height,
          color: effectiveColor,
          child: Material(
            color: Colors.transparent,
            child: bottom!,
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final potato = context.watch<PotatoModeProvider>();
    final effectiveColor = backgroundColor ?? AppColors.background(context);

    final effectiveOpacity = potato.blurEffectsEnabled ? opacity : 1.0;
    final hasBlur = potato.blurEffectsEnabled;

    final appBarContent = Container(
      color: effectiveColor.withValues(alpha: effectiveOpacity),
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
    );

    if (hasBlur) {
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: appBarContent,
        ),
      );
    }

    return appBarContent;
  }

  @override
  Size get preferredSize {
    final appBarHeight = kToolbarHeight + (bottom?.preferredSize.height ?? 0.0);
    return Size.fromHeight(appBarHeight);
  }
}
