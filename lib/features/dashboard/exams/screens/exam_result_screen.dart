import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exam_result_view.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/action_buttons_widget.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/services/result_share_service.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';

class ExamResultScreen extends StatefulWidget {
  final Exam exam;
  final Map<int, String?> userAnswers;
  final int score;
  final int accuracy;
  final int speedBonus;
  final int correctCount;
  final bool isFirstAttempt;

  const ExamResultScreen({
    super.key,
    required this.exam,
    required this.userAnswers,
    required this.score,
    required this.accuracy,
    required this.speedBonus,
    required this.correctCount,
    this.isFirstAttempt = true,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  bool _isSharing = false;

  Future<void> _shareResult() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userMetadata = authProvider.state.user?.userMetadata;

      await ResultShareService.shareExamResult(
        context: context,
        fullName: userMetadata?['full_name'],
        username: userMetadata?['username'],
        gradeRaw: userMetadata?['grade'],
        score: widget.score,
        accuracy: widget.accuracy,
        speedBonus: widget.speedBonus,
        correctCount: widget.correctCount,
        examTitle: widget.exam.title,
        examId: widget.exam.id,
        passPercentage: widget.exam.passPercentage,
        totalQuestions: widget.exam.questions.length,
      );
    } catch (e) {
      debugPrint('Failed to share result: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: TestKeys.examResultScreen,
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          title: const Text('نتيجة الاختبار'),
          automaticallyImplyLeading: false,
          actions: [
            if (!widget.isFirstAttempt)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppTokens.radiusMdAll,
                    ),
                    child: const Text(
                      'وضع التدريب',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_outlined),
              onPressed: _shareResult,
              tooltip: 'تحميل ومشاركة النتيجة',
            ),
          ],
        ),
        body: ExamResultView(
          exam: widget.exam,
          userAnswers: widget.userAnswers,
          correctCount: widget.correctCount,
          score: widget.score,
          accuracy: widget.accuracy,
          speedBonus: widget.speedBonus,
          padding: EdgeInsets.only(
            top:
                MediaQuery.paddingOf(context).top +
                kToolbarHeight +
                AppTokens.spacing16,
            left: AppTokens.spacing16,
            right: AppTokens.spacing16,
            bottom: AppTokens.spacing16,
          ),
          actions: ActionButtonsWidget(
            onHomePressed: () => context.goNamed('home'),
            onRetakePressed: () => context.pushReplacementNamed(
              'exam-interaction',
              pathParameters: {'id': widget.exam.id},
              extra: {
                'subjectId': widget.exam.subjectId,
                'subjectName': widget.exam.subject,
              },
            ),
          ),
        ),
      ),
    );
  }
}
