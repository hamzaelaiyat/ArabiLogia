import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';
import 'package:arabilogia/features/admin/widgets/preview_option_tile.dart';
import 'package:arabilogia/features/admin/widgets/preview_navigation_bar.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:go_router/go_router.dart';

class LecturePreviewScreen extends StatefulWidget {
  final Exam exam;
  const LecturePreviewScreen({super.key, required this.exam});

  @override
  State<LecturePreviewScreen> createState() => _LecturePreviewScreenState();
}

class _LecturePreviewScreenState extends State<LecturePreviewScreen> {
  final ExamRepository _repository = ExamRepository();
  int _currentQuestionIndex = 0;
  final Map<int, String?> _selectedAnswers = {};
  bool _isPublishing = false;
  late Exam _shuffledExam;

  @override
  void initState() {
    super.initState();
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
    if (_shuffledExam.questions.isEmpty) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          key: TestKeys.lecturePreviewScreen,
          appBar: AppBar(title: const Text('معاينة الامتحان (وضع المعلم)')),
          body: const Center(
            child: Text('لا توجد أسئلة في هذا الامتحان'),
          ),
        ),
      );
    }

    final currentQuestion = _shuffledExam.questions[_currentQuestionIndex];
    final progress =
        (_currentQuestionIndex + 1) / _shuffledExam.questions.length;
    final category = CategoryMetadata.getByName(_shuffledExam.subject);
    final categoryColor = category?.color ?? AppColors.primary;
    final isLast = _currentQuestionIndex >= _shuffledExam.questions.length - 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('معاينة الامتحان (وضع المعلم)'),
          actions: [
            IconButton(
              key: TestKeys.lecturePreviewShuffle,
              icon: const Icon(Icons.shuffle),
              tooltip: 'خلط الأسئلة',
              onPressed: () {
                setState(() {
                  _shuffledExam = widget.exam.copyWith(
                    questions: (List<Question>.from(widget.exam.questions)..shuffle())
                        .map((q) => q.shuffled())
                        .toList(),
                  );
                  _selectedAnswers.clear();
                  _currentQuestionIndex = 0;
                });
              },
            ),
            if (_isPublishing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              TextButton.icon(
                key: TestKeys.lecturePreviewSubmit,
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
              color: Colors.orange.withValues(alpha: 0.1),
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
              valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
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
                            color: categoryColor.withValues(alpha: 0.1),
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
                      return PreviewOptionTile(
                        option: option,
                        isSelected: _selectedAnswers[_currentQuestionIndex] == option.id,
                        categoryColor: categoryColor,
                        onTap: () {
                          setState(() {
                            _selectedAnswers[_currentQuestionIndex] = option.id;
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            PreviewNavigationBar(
              currentIndex: _currentQuestionIndex,
              totalQuestions: _shuffledExam.questions.length,
              categoryColor: categoryColor,
              onPrevious: _currentQuestionIndex > 0
                  ? () => setState(() => _currentQuestionIndex--)
                  : null,
              onNext: () {
                if (!isLast) {
                  setState(() => _currentQuestionIndex++);
                } else {
                  Navigator.of(context).pop();
                }
              },
              isLast: isLast,
            ),
          ],
        ),
      ),
    );
  }
}
