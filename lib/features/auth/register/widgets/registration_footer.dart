import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/strings.dart';

class RegistrationFooter extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isFirstStep;
  final bool isLastStep;
  final bool isLoading;
  final String? nextLabel;

  const RegistrationFooter({
    super.key,
    required this.onNext,
    required this.onBack,
    this.isFirstStep = false,
    this.isLastStep = false,
    this.isLoading = false,
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
              onPressed: isLoading ? null : onBack,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTokens.spacing8),
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
              height: AppTokens.buttonHeightMd,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEB8A00), Color(0xFFFFA726)],
                ),
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEB8A00).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  ),
                ),
                child: isLoading
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
