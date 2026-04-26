import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index <= currentStep;
        final isCurrent = index == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: AppTokens.spacing4),
          height: 6,
          width: isCurrent ? 24 : 12,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFEB8A00)
                : AppColors.authLabelColor(context).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            border: isCurrent
                ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1)
                : null,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: const Color(0xFFEB8A00).withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
