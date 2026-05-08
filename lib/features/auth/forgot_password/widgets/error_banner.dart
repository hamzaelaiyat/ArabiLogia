import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class ErrorBanner extends StatelessWidget {
  final String? message;

  const ErrorBanner({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacing12),
      margin: const EdgeInsets.only(bottom: AppTokens.spacing12),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: const Color(0xFFD32F2F)),
      ),
      child: Text(
        message!,
        style: const TextStyle(
          color: Color(0xFFD32F2F),
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
