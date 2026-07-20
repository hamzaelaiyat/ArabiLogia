import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/strings.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/constants/test_keys.dart';

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key = TestKeys.loginGoToRegister});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.noAccount,
          style: TextStyle(
            color: AppColors.authHeaderColor(context),
            fontSize: AppTokens.fontSizeMd,
          ),
        ),
        TextButton(
          onPressed: () => context.go(AppRoutes.register),
          child: const Text(
            AppStrings.register,
            style: TextStyle(
              color: Color(0xFFEB8A00),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
