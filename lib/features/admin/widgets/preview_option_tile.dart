import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';

class PreviewOptionTile extends StatelessWidget {
  final Option option;
  final bool isSelected;
  final Color? categoryColor;
  final VoidCallback? onTap;

  const PreviewOptionTile({
    super.key,
    required this.option,
    this.isSelected = false,
    this.categoryColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = categoryColor ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spacing12),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTokens.radiusLgAll,
        child: Container(
          padding: const EdgeInsets.all(AppTokens.spacing16),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : option.isCorrect
                    ? Colors.green.withValues(alpha: 0.05)
                    : AppColors.surface(context),
            borderRadius: AppTokens.radiusLgAll,
            border: Border.all(
              color: isSelected
                  ? color
                  : option.isCorrect
                      ? Colors.green.withValues(alpha: 0.5)
                      : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? color : AppColors.mutedColor(context),
              ),
              const SizedBox(width: AppTokens.spacing12),
              Expanded(
                child: Text(
                  option.text,
                  style: TextStyle(
                    fontWeight: isSelected || option.isCorrect
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (option.isCorrect)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
