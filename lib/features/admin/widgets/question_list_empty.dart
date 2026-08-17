import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/admin/widgets/question_list_add_button.dart';

class QuestionListEmpty extends StatelessWidget {
  final VoidCallback onAddQuestion;

  const QuestionListEmpty({
    super.key,
    required this.onAddQuestion,
  });

  @override
  Widget build(BuildContext context) {
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
                  QuestionListAddButton(onPressed: onAddQuestion),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
