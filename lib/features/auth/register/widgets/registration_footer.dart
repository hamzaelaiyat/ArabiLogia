import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/strings.dart';

class RegistrationFooter extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isFirstStep;
  final bool isLastStep;
  final bool isLoading;
  final bool showSuccess;
  final String? nextLabel;

  const RegistrationFooter({
    super.key,
    required this.onNext,
    required this.onBack,
    this.isFirstStep = false,
    this.isLastStep = false,
    this.isLoading = false,
    this.showSuccess = false,
    this.nextLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacing4),
      child: Row(
        children: [
          if (!isFirstStep) ...[
            TextButton(
              key: TestKeys.registerBackButton,
              onPressed: (isLoading || showSuccess) ? null : onBack,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacing8,
                ),
              ),
              child: Text(
                AppStrings.previous,
                style: TextStyle(
                  color: AppColors.authSecondaryColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppTokens.spacing4),
          ],
          Expanded(
            child: Container(
              height: AppTokens.isMobile(context)
                  ? AppTokens.buttonHeightLg
                  : AppTokens.buttonHeightMd,
              decoration: BoxDecoration(
                color: showSuccess ? Colors.green : const Color(0xFFEB8A00),
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              ),
              child: ElevatedButton(
                key: TestKeys.registerNextButton,
                onPressed: (isLoading || showSuccess) ? null : onNext,
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
                    ? const Icon(Icons.check_circle,
                        color: Colors.white, size: 24)
                    : isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            nextLabel ??
                                (isLastStep
                                    ? AppStrings.createAccount
                                    : AppStrings.next),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: AppTokens.fontSizeMd,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
