import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_text_styles.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class QuestionPaletteSheet extends StatelessWidget {
  final int totalQuestions;
  final int currentIndex;
  final Map<int, String?> selectedAnswers;
  final Map<int, bool> flagged;
  final Color categoryColor;
  final ValueChanged<int> onQuestionTap;

  const QuestionPaletteSheet({
    super.key,
    required this.totalQuestions,
    required this.currentIndex,
    required this.selectedAnswers,
    required this.flagged,
    required this.categoryColor,
    required this.onQuestionTap,
  });

  Widget _legendItem(BuildContext context, Color color, bool filled, String label, {IconData? icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 14, color: color)
        else
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: filled ? color : Colors.transparent,
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        const SizedBox(width: AppTokens.spacing2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.mutedColor(context),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.spacing16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الأسئلة',
            style: AppTextStyles.headingSm.copyWith(
              color: AppColors.foreground(context),
            ),
          ),
          const SizedBox(height: AppTokens.spacing4),
          Wrap(
            spacing: AppTokens.spacing8,
            children: [
              _legendItem(context, categoryColor, true, 'تم الإجابة'),
              _legendItem(context, AppColors.mutedColor(context), false, 'لم يتم'),
              _legendItem(context, AppColors.examWarning, false, 'مُعلَّم للمراجعة', icon: Icons.flag),
            ],
          ),
          const SizedBox(height: AppTokens.spacing8),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 56,
                mainAxisSpacing: AppTokens.spacing4,
                crossAxisSpacing: AppTokens.spacing4,
              ),
              itemCount: totalQuestions,
              itemBuilder: (context, index) {
                final isAnswered = selectedAnswers[index] != null;
                final isFlagged = flagged[index] ?? false;
                final isCurrent = index == currentIndex;
                final status = isFlagged
                    ? 'مُعلَّم'
                    : isAnswered
                        ? 'تم الإجابة'
                        : 'لم يتم';
                return Semantics(
                  label: 'سؤال ${index + 1}، $status',
                  button: true,
                  child: InkWell(
                    onTap: () => onQuestionTap(index),
                    borderRadius: AppTokens.radiusSmAll,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isAnswered
                                ? categoryColor
                                : Colors.transparent,
                            borderRadius: AppTokens.radiusSmAll,
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.foreground(context)
                                  : isAnswered
                                      ? categoryColor
                                      : AppColors.mutedColor(context),
                              width: isCurrent ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: AppTextStyles.bodyMd.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isAnswered
                                  ? Colors.white
                                  : AppColors.foreground(context),
                            ),
                          ),
                        ),
                        if (isFlagged)
                          const PositionedDirectional(
                            top: 2,
                            start: 2,
                            child: Icon(
                              Icons.flag,
                              size: 12,
                              color: AppColors.examWarning,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
