
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';
import 'package:arabilogia/features/admin/widgets/exam_preview_widget.dart';

class ExamPreviewContent extends StatelessWidget {
  final List<Question> questions;
  final List<QuestionSettings> questionSettings;

  const ExamPreviewContent({
    super.key,
    required this.questions,
    required this.questionSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabBgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final tabUnselectedColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade600;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: tabBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: tabUnselectedColor,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(icon: Icon(Icons.phone_android, size: 20), text: 'جوال'),
                Tab(icon: Icon(Icons.tablet_android, size: 20), text: 'لوحي'),
                Tab(icon: Icon(Icons.desktop_windows, size: 20), text: 'حاسوب'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                ExamPreviewWidget(
                  child: ExamPreviewQuestionsList(
                    questions: questions,
                    questionSettings: questionSettings,
                  ),
                  device: PreviewDevice.mobile,
                ),
                ExamPreviewWidget(
                  child: ExamPreviewQuestionsList(
                    questions: questions,
                    questionSettings: questionSettings,
                  ),
                  device: PreviewDevice.tablet,
                ),
                ExamPreviewWidget(
                  child: ExamPreviewQuestionsList(
                    questions: questions,
                    questionSettings: questionSettings,
                  ),
                  device: PreviewDevice.desktop,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExamPreviewQuestionsList extends StatelessWidget {
  final List<Question> questions;
  final List<QuestionSettings> questionSettings;

  const ExamPreviewQuestionsList({
    super.key,
    required this.questions,
    required this.questionSettings,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = AppColors.mutedColor(context);

    if (questions.isEmpty) {
      return Center(
        child: Text(
          'لا توجد أسئلة للمعاينة',
          style: TextStyle(color: mutedColor),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        final settings = index < questionSettings.length
            ? questionSettings[index]
            : const QuestionSettings();
        return QuestionPreviewCard(
          question: question,
          settings: settings,
          index: index,
        );
      },
    );
  }
}

class QuestionPreviewCard extends StatelessWidget {
  final Question question;
  final QuestionSettings settings;
  final int index;

  const QuestionPreviewCard({
    super.key,
    required this.question,
    required this.settings,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppColors.surface(context);
    final mutedColor = AppColors.mutedColor(context);
    final style = settings.textStyle;

    final textStyle = TextStyle(
      fontSize: style.fontSize,
      fontWeight: style.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: style.isItalic ? FontStyle.italic : FontStyle.normal,
      color: QuestionTextStyle.textColors[style.colorIndex],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'س ${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${settings.points.points} درجة',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: mutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(question.text, style: textStyle),
          const SizedBox(height: 12),
          ...question.options.map((option) => _buildOptionRow(context, option, style)),
        ],
      ),
    );
  }

  Widget _buildOptionRow(BuildContext context, Option option, QuestionTextStyle textStyle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = AppColors.foreground(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: option.isCorrect
            ? AppColors.success.withValues(alpha: 0.1)
            : (isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: option.isCorrect
              ? AppColors.success.withValues(alpha: 0.3)
              : (isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: option.isCorrect
                  ? AppColors.success.withValues(alpha: 0.2)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.2)),
              border: Border.all(
                color: option.isCorrect ? AppColors.success : Colors.grey,
                width: 2,
              ),
            ),
            child: option.isCorrect
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.success,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              option.text,
              style: TextStyle(
                fontSize: textStyle.fontSize - 2,
                fontWeight: textStyle.isBold
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: fgColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}