import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/question_passage.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/question_option_tile.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exam_navigation_bar.dart';

class ExamInteractionBody extends StatelessWidget {
  final Exam exam;
  final int currentQuestionIndex;
  final Map<int, String?> selectedAnswers;
  final Color categoryColor;
  final double progress;
  final bool isSubmitting;
  final void Function(int questionIndex, String optionId) onOptionSelected;
  final VoidCallback onSaveSession;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;

  const ExamInteractionBody({
    super.key,
    required this.exam,
    required this.currentQuestionIndex,
    required this.selectedAnswers,
    required this.categoryColor,
    required this.progress,
    required this.isSubmitting,
    required this.onOptionSelected,
    required this.onSaveSession,
    this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final currentQuestion = exam.questions[currentQuestionIndex];

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.surface(context),
          valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
          minHeight: 6,
        ),
        Expanded(
          child: Column(
            children: [
              if (currentQuestion.passage != null)
                Expanded(
                  flex: 2,
                  child: QuestionPassage(
                    passage: currentQuestion.passage!,
                    categoryColor: categoryColor,
                  ),
                ),
              if (currentQuestion.passage != null)
                const SizedBox(height: AppTokens.spacing16),
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السؤال ${currentQuestionIndex + 1} من ${exam.questions.length}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: AppColors.mutedColor(context),
                            ),
                      ),
                      const SizedBox(height: AppTokens.spacing8),
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          children: parseQuestionText(
                            currentQuestion.text,
                            isDark: Theme.of(context).brightness ==
                                Brightness.dark,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTokens.spacing24),
                      ...currentQuestion.options.map((option) {
                        final isSelected =
                            selectedAnswers[currentQuestionIndex] ==
                                option.id;
                        return QuestionOptionTile(
                          option: option,
                          isSelected: isSelected,
                          categoryColor: categoryColor,
                          onTap: () {
                            onOptionSelected(currentQuestionIndex, option.id);
                            onSaveSession();
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ExamNavigationBar(
          currentQuestionIndex: currentQuestionIndex,
          totalQuestions: exam.questions.length,
          onPrevious: onPrevious,
          onNext: onNext,
          isSubmitting: isSubmitting,
          hasSelectedAnswer:
              selectedAnswers[currentQuestionIndex] != null,
          categoryColor: categoryColor,
        ),
      ],
    );
  }
}
