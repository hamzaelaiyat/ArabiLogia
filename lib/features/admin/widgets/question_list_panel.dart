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
  final List<Map<String, String>> passages;
  final String? Function(String?) getPassageValue;
  final String? Function(String?) getPassageContent;
  final bool Function(String?) isSavedPassage;
  final bool isMobile;
  final VoidCallback onAddQuestion;
  final Function(int) onDeleteQuestion;
  final Function(int, Question) onUpdateQuestion;
  final Function(int, QuestionSettings?) onUpdateSettings;

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
    required this.onUpdateQuestion,
    required this.onUpdateSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark
          ? AppColors.bgDark.withValues(alpha: 0.5)
          : AppColors.bgLight.withValues(alpha: 0.5),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? AppTokens.spacing16 : AppTokens.spacing32,
              isMobile ? AppTokens.spacing16 : AppTokens.spacing32,
              isMobile ? AppTokens.spacing16 : AppTokens.spacing32,
              isMobile ? AppTokens.spacing12 : AppTokens.spacing16,
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
                          ? AppTokens.spacing16
                          : AppTokens.spacing32,
                      vertical: isMobile
                          ? AppTokens.spacing12
                          : AppTokens.spacing16,
                    ),
                    itemCount: questions.length + 1,
                    itemBuilder: (context, index) {
                      if (index == questions.length) {
                        return Padding(
                          padding: EdgeInsets.only(
                            top: AppTokens.spacing16,
                            bottom: isMobile
                                ? AppTokens.spacing16
                                : AppTokens.spacing32,
                          ),
                          child: _buildAddQuestionButton(isDark),
                        );
                      }
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: isMobile
                              ? AppTokens.spacing16
                              : AppTokens.spacing32,
                        ),
                        child: QuestionCard(
                          question: questions[index],
                          settings: index < questionSettings.length
                              ? questionSettings[index]
                              : null,
                          index: index,
                          passages: passages,
                          getPassageValue: getPassageValue,
                          getPassageContent: getPassageContent,
                          isSavedPassage: isSavedPassage,
                          isMobile: isMobile,
                          onDelete: () => onDeleteQuestion(index),
                          onUpdate: (q) => onUpdateQuestion(index, q),
                          onSettingsUpdate: (s) => onUpdateSettings(index, s),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: AppTokens.spacing24),
            Text(
              'لا توجد أسئلة بعد',
              style: TextStyle(
                fontSize: AppTokens.fontSizeXl,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: AppTokens.spacing12),
            Text(
              'ابدأ بإضافة أول سؤال للامتحان الخاص بك',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedColor(context)),
            ),
            const SizedBox(height: AppTokens.spacing32),
            _buildAddQuestionButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAddQuestionButton(bool isDark) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: onAddQuestion,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('إضافة سؤال جديد'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: AppTokens.radiusLgAll),
        ),
      ),
    );
  }
}
