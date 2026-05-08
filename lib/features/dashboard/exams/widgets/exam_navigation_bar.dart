import 'package:flutter/material.dart';
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

  const ExamNavigationBar({
    super.key,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    this.onPrevious,
    required this.onNext,
    required this.isSubmitting,
    required this.hasSelectedAnswer,
    required this.categoryColor,
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
      child: Row(
        children: [
          if (onPrevious != null)
            Expanded(
              child: OutlinedButton(
                onPressed: onPrevious,
                child: const Text('السابق'),
              ),
            ),
          if (onPrevious != null)
            const SizedBox(width: AppTokens.spacing16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: hasSelectedAnswer && !isSubmitting ? onNext : null,
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
    );
  }
}
