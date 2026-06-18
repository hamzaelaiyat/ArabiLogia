import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/strings.dart';

class LoginButton extends StatelessWidget {
  final bool isLoading;
  final bool showSuccess;
  final VoidCallback? onPressed;

  const LoginButton({
    super.key,
    required this.isLoading,
    this.showSuccess = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: AppTokens.isMobile(context)
          ? AppTokens.buttonHeightLg
          : AppTokens.buttonHeightMd,
      decoration: BoxDecoration(
        color: showSuccess ? Colors.green : const Color(0xFFEB8A00),
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      ),
      child: ElevatedButton(
        onPressed: (isLoading || showSuccess) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          ),
        ),
        child: showSuccess
            ? const Icon(Icons.check_circle, color: Colors.white, size: 24)
            : isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    AppStrings.login,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
      ),
    );
  }
}
