import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class GradientActionButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final String? errorText;

  const GradientActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: AppTokens.isMobile(context)
              ? AppTokens.buttonHeightLg
              : AppTokens.buttonHeightMd,
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
            onPressed: isLoading ? null : onPressed,
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
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.spacing8),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontWeight: FontWeight.bold,
                fontSize: AppTokens.fontSizeSm,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
