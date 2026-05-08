import 'package:flutter/material.dart';
import 'package:arabilogia/core/constants/strings.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/auth/widgets/auth_text_field.dart';
import 'package:arabilogia/features/auth/register/widgets/step_header.dart';

class ProfileStepForm extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController usernameController;

  const ProfileStepForm({
    super.key,
    required this.fullNameController,
    required this.usernameController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const StepHeader(title: 'البيانات الشخصية', icon: Icons.badge_outlined),
        const SizedBox(height: AppTokens.spacing12),
        AuthTextField(
          controller: fullNameController,
          label: AppStrings.fullName,
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال الاسم الكامل';
            }

            String normalized = value
                .replaceAll(RegExp(r'[إأآا]ة$'), 'ة')
                .replaceAll(RegExp(r'امة$'), 'أمة')
                .replaceAll(RegExp(r'امه$'), 'أمة')
                .replaceAll(RegExp(r'أمه$'), 'أمة');

            final words = normalized.trim().split(RegExp(r'\s+'));

            if (words.length < 3) {
              return 'يرجى إدخال الاسم الثلاثي على الأقل';
            }
            if (!RegExp(r'^[\u0600-\u06FF\s]+$').hasMatch(value)) {
              return 'يجب أن يكون الاسم الكامل باللغة العربية فقط';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTokens.spacing12),
        AuthTextField(
          controller: usernameController,
          label: AppStrings.username,
          icon: Icons.alternate_email,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال اسم المستخدم';
            }
            if (value.length < 3) {
              return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
            }
            if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) {
              return 'يجب أن يكون اسم المستخدم بالإنجليزية فقط (أحرف وأرقام)';
            }
            return null;
          },
        ),
      ],
    );
  }
}
