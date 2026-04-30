import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:go_router/go_router.dart';

class ExamPreviewScreen extends StatefulWidget {
  final Exam exam;
  const ExamPreviewScreen({super.key, required this.exam});

  @override
  State<ExamPreviewScreen> createState() => _ExamPreviewScreenState();
}

class _ExamPreviewScreenState extends State<ExamPreviewScreen> {
  final ExamRepository _repository = ExamRepository();
  int _currentQuestionIndex = 0;
  final Map<int, String?> _selectedAnswers = {};
  bool _isPublishing = false;
  late Exam _shuffledExam;

  @override
  void initState() {
    super.initState();
    // In preview, we want to see the real question order or shuffled at teacher's choice?
    // Let's shuffle like the real thing to test randomness.
    _shuffledExam = widget.exam.copyWith(
      questions: (List<Question>.from(
        widget.exam.questions,
      )..shuffle()).map((q) => q.shuffled()).toList(),
    );
  }

  Future<void> _handlePublish() async {
    setState(() => _isPublishing = true);
    try {
      await _repository.publishExam(widget.exam);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع الامتحان بنجاح إلى Supabase'),
            backgroundColor: Colors.green,
          ),
        );
        context.go(AppRoutes.teacherPanel);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الرفع: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _shuffledExam.questions[_currentQuestionIndex];
    final progress =
        (_currentQuestionIndex + 1) / _shuffledExam.questions.length;
    final category = CategoryMetadata.getByName(_shuffledExam.subject);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('معاينة الامتحان (وضع المعلم)'),
          actions: [
            if (_isPublishing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              TextButton.icon(
                onPressed: _handlePublish,
                icon: const Icon(Icons.cloud_upload, color: Colors.white),
                label: const Text(
                  'نشر إلى Supabase',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(backgroundColor: Colors.green),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Container(
              color: Colors.orange.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'هذه معاينة فقط. لن يتم حفظ الدرجات.',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surface(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                category?.color ?? AppColors.primary,
              ),
              minHeight: 6,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTokens.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentQuestion.passage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTokens.spacing16),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: AppTokens.radiusLgAll,
                          border: Border.all(
                            color: (category?.color ?? AppColors.primary)
                                .withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          currentQuestion.passage!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.8),
                        ),
                      ),
                      const SizedBox(height: AppTokens.spacing24),
                    ],
                    Text(
                      'السؤال ${_currentQuestionIndex + 1} من ${_shuffledExam.questions.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedColor(context),
                      ),
                    ),
                    const SizedBox(height: AppTokens.spacing8),
                    Text(
                      currentQuestion.text,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spacing24),
                    ...currentQuestion.options.map((option) {
                      final isSelected =
                          _selectedAnswers[_currentQuestionIndex] == option.id;
                      // In preview, highlight the correct answer subtly for the teacher
                      final isCorrect = option.isCorrect;

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTokens.spacing12,
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedAnswers[_currentQuestionIndex] =
                                  option.id;
                            });
                          },
                          borderRadius: AppTokens.radiusLgAll,
                          child: Container(
                            padding: const EdgeInsets.all(AppTokens.spacing16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (category?.color ?? AppColors.primary)
                                        .withOpacity(0.1)
                                  : isCorrect
                                  ? Colors.green.withOpacity(0.05)
                                  : AppColors.surface(context),
                              borderRadius: AppTokens.radiusLgAll,
                              border: Border.all(
                                color: isSelected
                                    ? (category?.color ?? AppColors.primary)
                                    : isCorrect
                                    ? Colors.green.withOpacity(0.5)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: isSelected
                                      ? (category?.color ?? AppColors.primary)
                                      : AppColors.mutedColor(context),
                                ),
                                const SizedBox(width: AppTokens.spacing12),
                                Expanded(
                                  child: Text(
                                    option.text,
                                    style: TextStyle(
                                      fontWeight: isSelected || isCorrect
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isCorrect)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                border: Border(
                  top: BorderSide(color: Colors.grey.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            setState(() => _currentQuestionIndex--),
                        child: const Text('السابق'),
                      ),
                    ),
                  if (_currentQuestionIndex > 0)
                    const SizedBox(width: AppTokens.spacing16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentQuestionIndex <
                            _shuffledExam.questions.length - 1) {
                          setState(() => _currentQuestionIndex++);
                        } else {
                          // Return to previous screen
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: category?.color ?? AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _currentQuestionIndex <
                                _shuffledExam.questions.length - 1
                            ? 'التالي'
                            : 'نهاية المعاينة',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
