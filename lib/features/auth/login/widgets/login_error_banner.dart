import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class LoginErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback? onResendVerification;

  const LoginErrorBanner({
    super.key,
    required this.error,
    this.onResendVerification,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.spacing8),
      child: Column(
        children: [
          Text(
            error,
            style: const TextStyle(
              color: Color(0xFFD32F2F),
              fontWeight: FontWeight.bold,
              fontSize: AppTokens.fontSizeSm,
            ),
            textAlign: TextAlign.center,
          ),
          if (onResendVerification != null)
            TextButton(
              onPressed: onResendVerification,
              child: const Text(
                'إعادة إرسال رمز التفعيل',
                style: TextStyle(
                  color: Color(0xFFEB8A00),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
