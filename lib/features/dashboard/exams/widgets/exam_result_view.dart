import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/celebration_overlay.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/score_summary_widget.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/stats_row_widget.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/question_review_widget.dart';

class ExamResultView extends StatelessWidget {
  final Exam exam;
  final Map<int, String?> userAnswers;
  final int correctCount;
  final int? score;
  final int? accuracy;
  final int? speedBonus;
  final Widget actions;
  final EdgeInsetsGeometry padding;

  const ExamResultView({
    super.key,
    required this.exam,
    required this.userAnswers,
    required this.correctCount,
    this.score,
    this.accuracy,
    this.speedBonus,
    required this.actions,
    this.padding = const EdgeInsets.all(AppTokens.spacing16),
  });

  bool get _isPractice => score == null;

  bool get _isPerfect => _isPractice
      ? exam.questions.isNotEmpty && correctCount == exam.questions.length
      : score == 100;

  List<int> _wrongAnswerIndices() {
    final wrong = <int>[];
    for (int i = 0; i < exam.questions.length; i++) {
      final question = exam.questions[i];
      final selectedId = userAnswers[i];
      final correctOption = question.options.cast<Option?>().firstWhere(
            (o) => o?.isCorrect == true,
            orElse: () => null,
          );
      if (selectedId != correctOption?.id) {
        wrong.add(i);
      }
    }
    return wrong;
  }

  @override
  Widget build(BuildContext context) {
    final wrongAnswerIndices = _wrongAnswerIndices();
    final totalQuestions = exam.questions.length;

    return CelebrationOverlay(
      celebrate: _isPerfect,
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          children: [
            if (_isPractice)
              _PracticeScoreSummary(
                correctCount: correctCount,
                totalQuestions: totalQuestions,
              )
            else
              ScoreSummaryWidget(
                score: score!,
                isPassed: score! >= exam.passPercentage,
              ),
            const SizedBox(height: AppTokens.spacing24),
            if (_isPractice)
              _PracticeStatsRow(
                correctCount: correctCount,
                totalQuestions: totalQuestions,
              )
            else
              StatsRowWidget(
                totalQuestions: totalQuestions,
                correctCount: correctCount,
                accuracy: accuracy ?? 0,
                speedBonus: speedBonus ?? 0,
              ),
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
            ] else if (_isPerfect)
              const _PerfectBanner(),
            const SizedBox(height: AppTokens.spacing32),
            actions,
          ],
        ),
      ),
    );
  }
}

class _PerfectBanner extends StatelessWidget {
  const _PerfectBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.spacing16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.examPass.withValues(alpha: 0.15),
            AppColors.examPass.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: AppTokens.radiusLgAll,
        border: Border.all(
          color: AppColors.examPass.withValues(alpha: 0.3),
        ),
      ),
      child: const Column(
        children: [
          Icon(Icons.stars, color: AppColors.examPass, size: 48),
          SizedBox(height: AppTokens.spacing8),
          Text(
            'أحسنت! جميع إجاباتك كانت صحيحة.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppTokens.fontSizeLg,
            ),
          ),
          SizedBox(height: AppTokens.spacing2),
          Text(
            'نتيجة كاملة 🎉',
            style: TextStyle(color: AppColors.examPass),
          ),
        ],
      ),
    );
  }
}

class _PracticeScoreSummary extends StatelessWidget {
  final int correctCount;
  final int totalQuestions;

  const _PracticeScoreSummary({
    required this.correctCount,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
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
                  value: totalQuestions > 0
                      ? correctCount / totalQuestions
                      : 0,
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
}

class _PracticeStatsRow extends StatelessWidget {
  final int correctCount;
  final int totalQuestions;

  const _PracticeStatsRow({
    required this.correctCount,
    required this.totalQuestions,
  });

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

  @override
  Widget build(BuildContext context) {
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
}
