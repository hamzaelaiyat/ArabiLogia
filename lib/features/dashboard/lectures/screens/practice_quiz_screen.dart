import 'package:flutter/material.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exam_interaction_body.dart';
import 'package:go_router/go_router.dart';

class PracticeQuizScreen extends StatefulWidget {
  final String examId;
  final String subjectId;
  final String subjectName;
  final String lectureId;

  const PracticeQuizScreen({
    super.key,
    required this.examId,
    required this.subjectId,
    required this.subjectName,
    required this.lectureId,
  });

  @override
  State<PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends State<PracticeQuizScreen> {
  final ExamRepository _repository = ExamRepository();
  Exam? _exam;
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  final Map<int, String?> _selectedAnswers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  Future<void> _loadExam() async {
    final exam = await _repository.loadExamById(
      widget.subjectId,
      widget.examId,
    );

    if (!mounted) return;

    if (exam != null) {
      final shuffledQuestions = (List<Question>.from(exam.questions)
            ..shuffle())
          .map((q) => q.shuffled())
          .toList();

      setState(() {
        _exam = exam.copyWith(questions: shuffledQuestions);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (Navigator.of(context).canPop()) {
        context.pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ في تحميل الامتحان')),
      );
    }
  }

  void _submitQuiz() {
    if (_isSubmitting) return;
    if (_exam == null || _exam!.questions.isEmpty) return;
    setState(() => _isSubmitting = true);

    int correctCount = 0;
    for (int i = 0; i < _exam!.questions.length; i++) {
      final question = _exam!.questions[i];
      final selectedId = _selectedAnswers[i];
      if (selectedId == null) continue;
      final correctOption = question.options.cast<Option?>().firstWhere(
        (o) => o?.isCorrect == true,
        orElse: () => null,
      );
      if (correctOption != null && selectedId == correctOption.id) {
        correctCount++;
      }
    }

    if (!mounted) return;

    context.pushReplacementNamed(
      'practice-result',
      extra: {
        'exam': _exam,
        'userAnswers': _selectedAnswers,
        'correctCount': correctCount,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_exam == null || _exam!.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('لا توجد أسئلة في هذا الاختبار'),
        ),
      );
    }

    final progress =
        (_currentQuestionIndex + 1) / _exam!.questions.length;
    final category = CategoryMetadata.getByName(_exam!.subject);
    final categoryColor = category?.color ?? AppColors.primary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        showDialog<bool>(
          context: context,
          builder: (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('هل أنت متأكد؟'),
              content: const Text('إذا خرجت الآن، ستفقد تقدمك في هذا الاختبار.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                    context.pop();
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('خروج على أي حال'),
                ),
              ],
            ),
          ),
        );
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          key: TestKeys.practiceQuizScreen,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Icon(category?.icon ?? Icons.quiz, color: category?.color),
                const SizedBox(width: 8),
                const Text('اختبار تدريبي', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          body: ExamInteractionBody(
            exam: _exam!,
            currentQuestionIndex: _currentQuestionIndex,
            selectedAnswers: _selectedAnswers,
            categoryColor: categoryColor,
            progress: progress,
            isSubmitting: _isSubmitting,
            onOptionSelected: (index, optionId) {
              setState(() {
                _selectedAnswers[index] = optionId;
              });
            },
            onSaveSession: () {},
            onPrevious: _currentQuestionIndex > 0
                ? () {
                    setState(() {
                      _currentQuestionIndex--;
                    });
                  }
                : null,
            onNext: () {
              if (_currentQuestionIndex <
                  _exam!.questions.length - 1) {
                setState(() {
                  _currentQuestionIndex++;
                });
              } else {
                if (!_isSubmitting) _submitQuiz();
              }
            },
          ),
        ),
      ),
    );
  }
}
