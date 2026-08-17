import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_text_styles.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class ExamNavigationBar extends StatelessWidget {
  final int currentQuestionIndex;
  final int totalQuestions;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final bool isSubmitting;
  final bool hasSelectedAnswer;
  final Color categoryColor;
  final bool isFlagged;
  final VoidCallback? onToggleFlag;
  final VoidCallback? onOpenPalette;

  const ExamNavigationBar({
    super.key,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    this.onPrevious,
    required this.onNext,
    required this.isSubmitting,
    required this.hasSelectedAnswer,
    required this.categoryColor,
    this.isFlagged = false,
    this.onToggleFlag,
    this.onOpenPalette,
  });

  @override
  Widget build(BuildContext context) {
    final isLastQuestion = currentQuestionIndex >= totalQuestions - 1;
    final buttonText = isLastQuestion ? 'إنهاء الاختبار' : 'التالي';

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(
          top: BorderSide(
            color: DividerTheme.of(context).color ??
                Colors.grey.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!hasSelectedAnswer)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.spacing4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: AppTokens.iconSizeXs,
                    color: AppColors.mutedColor(context),
                  ),
                  const SizedBox(width: AppTokens.spacing2),
                  Text(
                    'لم تجب على هذا السؤال بعد',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedColor(context),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              if (onOpenPalette != null)
                IconButton(
                  tooltip: 'قائمة الأسئلة',
                  onPressed: onOpenPalette,
                  icon: const Icon(Icons.grid_view),
                ),
              if (onToggleFlag != null)
                IconButton(
                  tooltip: 'وضع علامة للمراجعة',
                  onPressed: onToggleFlag,
                  icon: Icon(
                    isFlagged ? Icons.flag : Icons.flag_outlined,
                    color: isFlagged
                        ? AppColors.examWarning
                        : AppColors.mutedColor(context),
                  ),
                ),
              if (onPrevious != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPrevious,
                    child: const Text('السابق'),
                  ),
                ),
              if (onPrevious != null)
                const SizedBox(width: AppTokens.spacing8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: !isSubmitting ? onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: categoryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(buttonText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
