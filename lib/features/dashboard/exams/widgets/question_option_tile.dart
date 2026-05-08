import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';

class QuestionOptionTile extends StatelessWidget {
  final Option option;
  final bool isSelected;
  final Color categoryColor;
  final VoidCallback onTap;

  const QuestionOptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.categoryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spacing12),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTokens.radiusLgAll,
        child: Container(
          padding: const EdgeInsets.all(AppTokens.spacing16),
          decoration: BoxDecoration(
            color: isSelected
                ? categoryColor.withValues(alpha: 0.1)
                : AppColors.surface(context),
            borderRadius: AppTokens.radiusLgAll,
            border: Border.all(
              color: isSelected ? categoryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? categoryColor
                        : AppColors.mutedColor(context),
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: categoryColor,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppTokens.spacing12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: AppColors.foreground(context),
                    ),
                    children: parseQuestionText(
                      option.text,
                      isDark:
                          Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
