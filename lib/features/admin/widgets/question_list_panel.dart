import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';
import 'package:arabilogia/features/auth/widgets/glass_container.dart';
import 'package:arabilogia/features/admin/widgets/question_card.dart';

class QuestionListPanel extends StatelessWidget {
  final List<Question> questions;
  final List<QuestionSettings> questionSettings;
  final bool isMobile;
  final VoidCallback onAddQuestion;
  final Function(int) onDeleteQuestion;
  final Function(int, Question) onUpdateQuestion;
  final Function(int, QuestionSettings?) onUpdateSettings;

  const QuestionListPanel({
    super.key,
    required this.questions,
    required this.questionSettings,
    this.isMobile = false,
    required this.onAddQuestion,
    required this.onDeleteQuestion,
    required this.onUpdateQuestion,
    required this.onUpdateSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: AppColors.surface(context),
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
                const Icon(Icons.quiz_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'الأسئلة',
                  style: TextStyle(
                    fontSize: AppTokens.fontSize2xl,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTokens.fontFamilyDisplay,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  'إجمالي الأسئلة: ${questions.length}',
                  style: TextStyle(
                    color: AppColors.mutedColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: questions.isEmpty
                ? _buildEmptyState(context, isDark)
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile
                          ? AppTokens.spacing12
                          : AppTokens.spacing32,
                      vertical: isMobile
                          ? AppTokens.spacing8
                          : AppTokens.spacing16,
                    ),
                    itemCount: questions.length + 1,
                    itemBuilder: (context, index) {
                      if (index == questions.length) {
                        if (isMobile) return const SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(
                            top: isMobile ? AppTokens.spacing8 : AppTokens.spacing16,
                            bottom: isMobile
                                ? AppTokens.spacing8
                                : AppTokens.spacing32,
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
                            bottom: isMobile
                                ? AppTokens.spacing8
                                : AppTokens.spacing32,
                          ),
                          child: QuestionCard(
                            question: questions[index],
                            settings: index < questionSettings.length
                                ? questionSettings[index]
                                : null,
                            index: index,
                            isMobile: isMobile,
                            onDelete: () => onDeleteQuestion(index),
                            onUpdate: (q) => onUpdateQuestion(index, q),
                            onSettingsUpdate: (s) => onUpdateSettings(index, s),
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
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
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
    return ElevatedButton.icon(
      onPressed: onAddQuestion,
      icon: const Icon(Icons.add_circle_outline, size: 20),
      label: const Text('إضافة سؤال جديد'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: AppTokens.radiusMdAll,
        ),
        elevation: AppTokens.elevationMd,
        shadowColor: AppColors.primary.withValues(alpha: 0.4),
      ),
    );
  }
}
