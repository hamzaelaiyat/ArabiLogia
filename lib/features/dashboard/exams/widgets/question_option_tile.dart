import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';

const List<String> _optionLetters = ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز', 'ح'];

class QuestionOptionTile extends StatelessWidget {
  final Option option;
  final int index;
  final bool isSelected;
  final Color categoryColor;
  final VoidCallback onTap;

  const QuestionOptionTile({
    super.key,
    required this.option,
    this.index = 0,
    required this.isSelected,
    required this.categoryColor,
    required this.onTap,
  });

  String get _letter =>
      index < _optionLetters.length ? _optionLetters[index] : '${index + 1}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spacing12),
      child: Semantics(
        label: 'الخيار $_letter، ${isSelected ? 'محدد' : 'غير محدد'}',
        button: true,
        selected: isSelected,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: AppTokens.radiusLgAll,
          child: Container(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            decoration: BoxDecoration(
              color: isSelected
                  ? categoryColor.withValues(alpha: 0.18)
                  : AppColors.surface(context),
              borderRadius: AppTokens.radiusLgAll,
              border: Border.all(
                color: isSelected ? categoryColor : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: categoryColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? categoryColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? categoryColor
                          : AppColors.mutedColor(context),
                    ),
                  ),
                  child: Text(
                    _letter,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeSm,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : AppColors.mutedColor(context),
                    ),
                  ),
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
      ),
    );
  }
}
