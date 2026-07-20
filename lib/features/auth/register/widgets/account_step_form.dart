import 'package:flutter/material.dart';
import 'package:arabilogia/core/constants/strings.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/auth/widgets/auth_text_field.dart';
import 'package:arabilogia/features/auth/register/widgets/step_header.dart';

class AccountStepForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;
  final Map<String, String> fieldErrors;

  const AccountStepForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
    this.fieldErrors = const {},
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const StepHeader(
          title: 'بيانات الحساب',
          icon: Icons.lock_person_outlined,
        ),
        const SizedBox(height: AppTokens.spacing12),
        AuthTextField(
          fieldKey: TestKeys.registerEmailField,
          controller: emailController,
          label: AppStrings.email,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال البريد الإلكتروني';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'البريد الإلكتروني غير صالح';
            }
            return null;
          },
        ),
        if (fieldErrors.containsKey('email'))
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 16),
            child: Text(
              fieldErrors['email']!,
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
          ),
        const SizedBox(height: AppTokens.spacing12),
        AuthTextField(
          fieldKey: TestKeys.registerPasswordField,
          controller: passwordController,
          label: AppStrings.password,
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: obscurePassword,
          onToggleVisibility: onTogglePasswordVisibility,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال كلمة المرور';
            }
            if (value.length < 6) {
              return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
            }
            return null;
          },
        ),
        if (fieldErrors.containsKey('password'))
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 16),
            child: Text(
              fieldErrors['password']!,
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
          ),
        const SizedBox(height: AppTokens.spacing12),
        AuthTextField(
          fieldKey: TestKeys.registerConfirmPasswordField,
          controller: confirmPasswordController,
          label: AppStrings.confirmPassword,
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: obscureConfirmPassword,
          onToggleVisibility: onToggleConfirmPasswordVisibility,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى تأكيد كلمة المرور';
            }
            if (value != passwordController.text) {
              return 'كلمات المرور غير متطابقة';
            }
            return null;
          },
        ),
      ],
    );
  }
}
