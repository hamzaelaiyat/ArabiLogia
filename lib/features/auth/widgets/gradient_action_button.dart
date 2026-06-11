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
            color: const Color(0xFFEB8A00),
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
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
