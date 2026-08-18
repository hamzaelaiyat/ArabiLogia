import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_text_styles.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/exam_flip_transition.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/question_passage.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/question_option_tile.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exam_navigation_bar.dart';

class ExamInteractionBody extends StatefulWidget {
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
  final bool isFlagged;
  final VoidCallback? onToggleFlag;
  final VoidCallback? onOpenPalette;

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
    this.isFlagged = false,
    this.onToggleFlag,
    this.onOpenPalette,
  });

  @override
  State<ExamInteractionBody> createState() => _ExamInteractionBodyState();
}

class _ExamInteractionBodyState extends State<ExamInteractionBody> {
  bool _passageExpanded = true;

  int get _answeredCount =>
      widget.selectedAnswers.values.where((v) => v != null).length;

  Widget _buildPassage(BuildContext context, String passage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _passageExpanded = !_passageExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacing16,
              vertical: AppTokens.spacing4,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: AppTokens.iconSizeXs,
                  color: widget.categoryColor,
                ),
                const SizedBox(width: AppTokens.spacing4),
                Text(
                  'نص القراءة',
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.categoryColor,
                  ),
                ),
                const Spacer(),
                Icon(
                  _passageExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.mutedColor(context),
                ),
              ],
            ),
          ),
        ),
        if (_passageExpanded)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: QuestionPassage(
                passage: passage,
                categoryColor: widget.categoryColor,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.exam.questions[widget.currentQuestionIndex];
    final total = widget.exam.questions.length;

    return Column(
      children: [
        LinearProgressIndicator(
          value: widget.progress,
          backgroundColor: AppColors.surface(context),
          valueColor: AlwaysStoppedAnimation<Color>(widget.categoryColor),
          minHeight: 6,
        ),
        if (currentQuestion.passage != null)
          _buildPassage(context, currentQuestion.passage!),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppTokens.spacing16),
            child: ExamFlipTransition(
              child: Column(
                key: ValueKey<int>(widget.currentQuestionIndex),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spacing6,
                      vertical: AppTokens.spacing2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.categoryColor.withValues(alpha: 0.1),
                      borderRadius: AppTokens.radiusFullAll,
                    ),
                    child: Text(
                      'سؤال ${widget.currentQuestionIndex + 1} من $total · تمت الإجابة على $_answeredCount من $total',
                      style: AppTextStyles.caption.copyWith(
                        color: widget.categoryColor,
                        fontWeight: FontWeight.bold,
                      ),
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
                  ...List.generate(currentQuestion.options.length, (i) {
                    final option = currentQuestion.options[i];
                    final isSelected =
                        widget.selectedAnswers[widget.currentQuestionIndex] ==
                            option.id;
                    return QuestionOptionTile(
                      option: option,
                      index: i,
                      isSelected: isSelected,
                      categoryColor: widget.categoryColor,
                      onTap: () {
                        widget.onOptionSelected(
                          widget.currentQuestionIndex,
                          option.id,
                        );
                        widget.onSaveSession();
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.spacing8),
            child: ExamNavigationBar(
              currentQuestionIndex: widget.currentQuestionIndex,
              totalQuestions: total,
              onPrevious: widget.onPrevious,
              onNext: widget.onNext,
              isSubmitting: widget.isSubmitting,
              hasSelectedAnswer:
                  widget.selectedAnswers[widget.currentQuestionIndex] != null,
              categoryColor: widget.categoryColor,
              isFlagged: widget.isFlagged,
              onToggleFlag: widget.onToggleFlag,
              onOpenPalette: widget.onOpenPalette,
            ),
          ),
        ),
      ],
    );
  }
}
