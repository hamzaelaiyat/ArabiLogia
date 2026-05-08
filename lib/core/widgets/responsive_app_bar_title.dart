import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class ResponsiveAppBarTitle extends StatelessWidget {
  final String desktopTitle;

  const ResponsiveAppBarTitle(this.desktopTitle, {super.key});

  @override
  Widget build(BuildContext context) {
    if (AppTokens.isDesktop(context)) {
      return Text(
        desktopTitle,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }
    return Image.asset(
      'assets/images/logo-removedbg.png',
      height: 56,
      fit: BoxFit.contain,
    );
  }
}
