import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/strings.dart';

class ForgotPasswordHeader extends StatelessWidget {
  final bool isSubmitted;

  const ForgotPasswordHeader({super.key, required this.isSubmitted});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo-removedbg.png',
          height: 80,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: AppTokens.spacing12),
        Text(
          AppStrings.forgotPassword,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.authHeaderColor(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTokens.spacing8),
        Text(
          isSubmitted
              ? 'تم إرسال رمز إعادة التعيين المكون من 6 إلى 8 أرقام إلى بريدك الإلكتروني'
              : 'أدخل بريدك الإلكتروني لإرسال رمز إعادة التعيين المكون من 6 إلى 8 أرقام',
          style: TextStyle(
            color: AppColors.authTextColor(context),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
