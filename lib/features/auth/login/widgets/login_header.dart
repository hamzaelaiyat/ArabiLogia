import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/strings.dart';

class LoginHeader extends StatelessWidget {
  final bool isMobile;

  const LoginHeader({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo-removedbg.png',
          height: isMobile ? 80 : 100,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: AppTokens.spacing12),
        Text(
          AppStrings.login,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFEB8A00),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
