import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

/// Full-screen branded boot splash shown while the app resolves its first
/// destination (student dashboard, teacher dashboard, or update screen).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Center(
        child: Image.asset(
          'assets/images/logo-removedbg.png',
          height: 80,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
