import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/question_review_widget.dart';
import 'package:go_router/go_router.dart';

class PracticeResultScreen extends StatelessWidget {
  final Exam exam;
  final Map<int, String?> userAnswers;
  final int correctCount;

  const PracticeResultScreen({
    super.key,
    required this.exam,
    required this.userAnswers,
    required this.correctCount,
  });

  @override
  Widget build(BuildContext context) {
    final totalQuestions = exam.questions.length;
    final wrongAnswerIndices = <int>[];
    for (int i = 0; i < totalQuestions; i++) {
      final question = exam.questions[i];
      final selectedId = userAnswers[i];
      final correctOption = question.options.cast<Option?>().firstWhere(
        (o) => o?.isCorrect == true,
        orElse: () => null,
      );
      if (selectedId != correctOption?.id) {
        wrongAnswerIndices.add(i);
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const GlassAppBar(
          title: Text('نتيجة الاختبار التدريبي'),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            top:
                MediaQuery.paddingOf(context).top +
                kToolbarHeight +
                AppTokens.spacing16,
            left: AppTokens.spacing16,
            right: AppTokens.spacing16,
            bottom: AppTokens.spacing16,
          ),
          child: Column(
            children: [
              _buildScoreSummary(context, totalQuestions),
              const SizedBox(height: AppTokens.spacing24),
              _buildStatsRow(context, totalQuestions),
              const SizedBox(height: AppTokens.spacing32),

              if (wrongAnswerIndices.isNotEmpty) ...[
                const ReviewHeaderWidget(),
                const SizedBox(height: AppTokens.spacing16),
                ...wrongAnswerIndices.map(
                  (index) => QuestionReviewCardWidget(
                    question: exam.questions[index],
                    index: index,
                    selectedId: userAnswers[index],
                  ),
                ),
              ] else ...[
                const Icon(Icons.stars, color: AppColors.primary, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'أحسنت! جميع إجاباتك كانت صحيحة.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],

              const SizedBox(height: AppTokens.spacing32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      context.pop();
                    } else {
                      context.goNamed('home');
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('العودة'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTokens.spacing8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTokens.radiusMdAll,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreSummary(BuildContext context, int totalQuestions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.spacing32),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppTokens.radiusLgAll,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: totalQuestions > 0 ? correctCount / totalQuestions : 0,
                strokeWidth: 10,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$correctCount/$totalQuestions',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'الإجابات الصحيحة',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.mutedColor(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            correctCount == totalQuestions
                ? 'أحسنت! جميع إجاباتك كانت صحيحة'
                : 'حاول مرة أخرى لتحسين مستواك',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, int totalQuestions) {
    return Row(
      children: [
        _buildStatCard(
          context,
          'الأسئلة',
          '$totalQuestions',
          Icons.quiz_outlined,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          context,
          'الصحيحة',
          '$correctCount',
          Icons.check_circle_outline,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          context,
          'الخاطئة',
          '${totalQuestions - correctCount}',
          Icons.close,
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: AppTokens.radiusMdAll,
          border: Border.all(
            color: (color ?? AppColors.primary).withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color ?? AppColors.primary),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.mutedColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
