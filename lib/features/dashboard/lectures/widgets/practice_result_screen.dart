import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exam_result_view.dart';
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const GlassAppBar(
          title: Text('نتيجة الاختبار التدريبي'),
          automaticallyImplyLeading: false,
        ),
        body: ExamResultView(
          exam: exam,
          userAnswers: userAnswers,
          correctCount: correctCount,
          padding: EdgeInsets.only(
            top:
                MediaQuery.paddingOf(context).top +
                kToolbarHeight +
                AppTokens.spacing16,
            left: AppTokens.spacing16,
            right: AppTokens.spacing16,
            bottom: AppTokens.spacing16,
          ),
          actions: SizedBox(
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
        ),
      ),
    );
  }
}
