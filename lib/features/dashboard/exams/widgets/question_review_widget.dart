import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';

class ReviewHeaderWidget extends StatelessWidget {
  const ReviewHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.analytics_outlined,
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        const Text(
          'مراجعة الأخطاء',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: AppTokens.radiusFullAll,
          ),
          child: const Text(
            'أخطاء فقط',
            style: TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class QuestionReviewCardWidget extends StatelessWidget {
  final Question question;
  final int index;
  final String? selectedId;

  const QuestionReviewCardWidget({
    super.key,
    required this.question,
    required this.index,
    required this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    final correctOption = question.options.cast<Option?>().firstWhere(
      (o) => o?.isCorrect == true,
      orElse: () => null,
    );
    if (correctOption == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppTokens.radiusLgAll,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'سؤال رقم ${index + 1}',
                style: const TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.foreground(context),
              ),
              children: parseQuestionText(
                question.text,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _AnswerBox(
            label: 'إجابتك:',
            text: () {
              if (selectedId == null) return 'لم تجب';
              final match = question.options.cast<Option?>().firstWhere(
                (o) => o?.id == selectedId,
                orElse: () => null,
              );
              return match?.text ?? 'لم تجب';
            }(),
            isCorrect: false,
          ),
          const SizedBox(height: 8),
          _AnswerBox(
            label: 'الإجابة الصحيحة:',
            text: correctOption.text,
            isCorrect: true,
          ),
          if (question.explanation != null &&
              question.explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _ExplanationBox(explanation: question.explanation!),
          ],
        ],
      ),
    );
  }
}

class _AnswerBox extends StatelessWidget {
  final String label;
  final String text;
  final bool isCorrect;

  const _AnswerBox({
    required this.label,
    required this.text,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isCorrect ? AppColors.success : AppColors.error).withValues(
          alpha: 0.05,
        ),
        borderRadius: AppTokens.radiusMdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.mutedColor(context),
            ),
          ),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isCorrect ? AppColors.success : AppColors.error,
              ),
              children: parseQuestionText(text, isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplanationBox extends StatelessWidget {
  final String explanation;

  const _ExplanationBox({required this.explanation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppTokens.radiusMdAll,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: 6),
              Text(
                'الشرح والتوضيح:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.foreground(context),
              ),
              children: parseQuestionText(explanation, isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}
