import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';
import 'package:arabilogia/features/admin/widgets/question_card.dart';

class QuestionListPanel extends StatelessWidget {
  final List<Question> questions;
  final List<QuestionSettings> questionSettings;
  final List<Map<String, String>> passages;
  final String? Function(String?) getPassageValue;
  final String? Function(String?) getPassageContent;
  final bool Function(String?) isSavedPassage;
  final bool isMobile;
  final VoidCallback onAddQuestion;
  final Function(int) onDeleteQuestion;
  final Function(int) onDuplicateQuestion;
  final Function(int, Question) onUpdateQuestion;
  final Function(int, QuestionSettings?) onUpdateSettings;
  final Function(int, int)? onReorderQuestions;

  const QuestionListPanel({
    super.key,
    required this.questions,
    required this.questionSettings,
    required this.passages,
    required this.getPassageValue,
    required this.getPassageContent,
    required this.isSavedPassage,
    this.isMobile = false,
    required this.onAddQuestion,
    required this.onDeleteQuestion,
    required this.onDuplicateQuestion,
    required this.onUpdateQuestion,
    required this.onUpdateSettings,
    this.onReorderQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? AppTokens.spacing12 : AppTokens.spacing32,
              isMobile ? AppTokens.spacing12 : AppTokens.spacing32,
              isMobile ? AppTokens.spacing12 : AppTokens.spacing32,
              isMobile ? AppTokens.spacing8 : AppTokens.spacing16,
            ),
            child: Row(
              children: [
                if (!isMobile) ...[
                  const Icon(Icons.quiz_outlined, color: AppColors.primary),
                  const SizedBox(width: 12),
                ],
                Text(
                  isMobile ? 'الأسئلة (${questions.length})' : 'بنك الأسئلة',
                  style: TextStyle(
                    fontSize: isMobile ? AppTokens.fontSizeLg : AppTokens.fontSize2xl,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTokens.fontFamilyDisplay,
                    color: AppColors.foreground(context),
                    letterSpacing: -0.5,
                  ),
                ),
                if (!isMobile) ...[
                  const Spacer(),
                  Text(
                    'إجمالي الأسئلة: ${questions.length}',
                    style: TextStyle(
                      color: AppColors.mutedColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: questions.isEmpty
                ? _buildEmptyState(context, isDark)
                : onReorderQuestions != null
                    ? _buildReorderableList(context, isDark)
                    : _buildRegularList(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableList(BuildContext context, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          clipBehavior: Clip.none,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppTokens.spacing12 : AppTokens.spacing32,
                vertical: isMobile ? AppTokens.spacing8 : AppTokens.spacing16,
              ),
              itemCount: questions.length + 1,
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < questions.length && newIndex <= questions.length) {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  onReorderQuestions!(oldIndex, newIndex);
                }
              },
              proxyDecorator: (child, index, animation) {
                return Material(
                  elevation: 8,
                  color: Colors.transparent,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                if (index == questions.length) {
                  if (isMobile) return SizedBox.shrink(key: ValueKey('add_question_placeholder_$index'));
                  return Padding(
                    key: const ValueKey('add_question_button'),
                    padding: EdgeInsets.only(
                      top: isMobile ? AppTokens.spacing8 : AppTokens.spacing16,
                      bottom: isMobile ? AppTokens.spacing8 : AppTokens.spacing32,
                    ),
                    child: _buildAddQuestionButton(isDark),
                  );
                }
                return TweenAnimationBuilder<double>(
                  key: ValueKey(questions[index].id),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: AppTokens.durationMd,
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: isMobile ? AppTokens.spacing8 : AppTokens.spacing24,
                    ),
                    child: QuestionCard(
                      key: ValueKey(questions[index].id),
                      question: questions[index],
                      settings: index < questionSettings.length ? questionSettings[index] : null,
                      index: index,
                      passages: passages,
                      getPassageValue: getPassageValue,
                      getPassageContent: getPassageContent,
                      isSavedPassage: isSavedPassage,
                      isMobile: isMobile,
                      onDelete: () => onDeleteQuestion(index),
                      onDuplicate: () => onDuplicateQuestion(index),
                      onUpdate: (q) => onUpdateQuestion(index, q),
                      onSettingsUpdate: (s) => onUpdateSettings(index, s),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegularList(BuildContext context, bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppTokens.spacing12 : AppTokens.spacing32,
        vertical: isMobile ? AppTokens.spacing8 : AppTokens.spacing16,
      ),
      itemCount: questions.length + 1,
      itemBuilder: (context, index) {
        if (index == questions.length) {
          if (isMobile) return SizedBox.shrink(key: ValueKey('add_question_placeholder_reg_$index'));
          return Padding(
            padding: EdgeInsets.only(
              top: isMobile ? AppTokens.spacing8 : AppTokens.spacing16,
              bottom: isMobile ? AppTokens.spacing8 : AppTokens.spacing32,
            ),
            child: _buildAddQuestionButton(isDark),
          );
        }
        return TweenAnimationBuilder<double>(
          key: ValueKey(questions[index].id),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: AppTokens.durationMd,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.only(
              bottom: isMobile ? AppTokens.spacing8 : AppTokens.spacing32,
            ),
            child: QuestionCard(
              key: ValueKey(questions[index].id),
              question: questions[index],
              settings: index < questionSettings.length ? questionSettings[index] : null,
              index: index,
              passages: passages,
              getPassageValue: getPassageValue,
              getPassageContent: getPassageContent,
              isSavedPassage: isSavedPassage,
              isMobile: isMobile,
              onDelete: () => onDeleteQuestion(index),
              onDuplicate: () => onDuplicateQuestion(index),
              onUpdate: (q) => onUpdateQuestion(index, q),
              onSettingsUpdate: (s) => onUpdateSettings(index, s),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final surfaceColor = AppColors.surface(context);
    final fgColor = AppColors.foreground(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.quiz_outlined,
                size: 60,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppTokens.spacing24),
            Text(
              'لا توجد أسئلة بعد',
              style: TextStyle(
                fontSize: AppTokens.fontSizeXl,
                fontWeight: FontWeight.bold,
                color: fgColor,
              ),
            ),
            const SizedBox(height: AppTokens.spacing8),
            Text(
              'ابدأ بإضافة أول سؤال للامتحان',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTokens.fontSizeMd,
                color: AppColors.mutedColor(context),
              ),
            ),
            const SizedBox(height: AppTokens.spacing32),
            Container(
              padding: const EdgeInsets.all(AppTokens.spacing20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: AppTokens.radiusLgAll,
              ),
              child: Column(
                children: [
                  Text(
                    'إبدأ الآن',
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeMd,
                      fontWeight: FontWeight.w600,
                      color: fgColor,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacing12),
                  _buildAddQuestionButton(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddQuestionButton(bool isDark) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppTokens.radiusFullAll,
          boxShadow: AppTokens.shadowOutside,
        ),
        child: ElevatedButton.icon(
          onPressed: onAddQuestion,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'إضافة سؤال جديد',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.2),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: const StadiumBorder(),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}