import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exam_interaction_body.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exit_confirmation_dialog.dart';
import 'package:arabilogia/providers/contextual_sidebar_provider.dart';
import 'package:arabilogia/features/dashboard/exams/providers/exam_provider.dart';
import 'package:provider/provider.dart';
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
  final Map<int, bool> _flagged = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          context.read<ExamProvider>().startExam();
        } catch (_) {}
      }
    });
    _loadExam();
  }

  @override
  void dispose() {
    try {
      context.read<ExamProvider>().endExam();
      context.read<ContextualSidebarProvider>().clearSidebar();
    } catch (_) {}
    super.dispose();
  }

  void _updateSidebar() {
    if (_exam == null || !mounted) return;
    try {
      context.read<ContextualSidebarProvider>().updateExamSidebarState(
            currentIndex: _currentQuestionIndex,
            selectedAnswers: _selectedAnswers,
            flaggedQuestions: _flagged,
          );
    } catch (_) {}
  }

  void _registerSidebar() {
    if (_exam == null || !mounted) return;
    try {
      final category = CategoryMetadata.getById(widget.subjectId);
      context.read<ContextualSidebarProvider>().setExamSidebar(
            ExamSidebarData(
              examId: widget.examId,
              title: _exam!.title,
              categoryName: widget.subjectName.isNotEmpty
                  ? widget.subjectName
                  : (category?.name ?? 'تمرين'),
              categoryColor: category?.color ?? AppColors.primary,
              questionCount: _exam!.questions.length,
              currentIndex: _currentQuestionIndex,
              selectedAnswers: _selectedAnswers,
              flaggedQuestions: _flagged,
              onSelectQuestion: (index) {
                if (mounted) {
                  setState(() => _currentQuestionIndex = index);
                  _updateSidebar();
                }
              },
              onToggleFlag: (index) {
                if (mounted) {
                  setState(() {
                    _flagged[index] = !(_flagged[index] ?? false);
                  });
                  _updateSidebar();
                }
              },
              onExitExam: () async {
                final shouldPop = await showExitConfirmationDialog(context);
                if (shouldPop && mounted) {
                  try {
                    context.read<ExamProvider>().endExam();
                  } catch (_) {}
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go(AppRoutes.lectures);
                  }
                }
              },
            ),
          );
    } catch (_) {}
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
      _registerSidebar();
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

  Future<void> _submitQuiz() async {
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

    final total = _exam!.questions.length;
    final score = total > 0 ? (correctCount / total * 100).toDouble() : 0.0;

    // Persist score locally
    await ScoreRepository().saveScoreLocally(widget.examId, score, correctCount * 10);

    // Persist completion in lecture progress if lectureId exists
    if (widget.lectureId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'lecture_progress_${widget.lectureId}';
      final completed = prefs.getStringList(key) ?? [];
      if (!completed.contains(widget.examId)) {
        completed.add(widget.examId);
        await prefs.setStringList(key, completed);
      }
    }

    if (!mounted) return;

    try {
      context.read<ExamProvider>().endExam();
      context.read<ContextualSidebarProvider>().clearSidebar();
    } catch (_) {}

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
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showExitConfirmationDialog(context);
        if (shouldPop && context.mounted) {
          context.pop();
        }
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
            actions: [
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('إنهاء الاختبار'),
                      content: const Text('هل تريد تسليم وإنهاء الاختبار القصير الآن؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('متابعة الحل'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('تسليم وإنهاء'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && !_isSubmitting) {
                    _submitQuiz();
                  }
                },
                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                label: const Text('إنهاء الاختبار', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  final shouldPop = await showExitConfirmationDialog(context);
                  if (shouldPop && context.mounted) {
                    context.pop();
                  }
                },
              ),
            ],
          ),
          body: ExamInteractionBody(
            exam: _exam!,
            currentQuestionIndex: _currentQuestionIndex,
            selectedAnswers: _selectedAnswers,
            categoryColor: categoryColor,
            progress: progress,
            isSubmitting: _isSubmitting,
            isFlagged: _flagged[_currentQuestionIndex] ?? false,
            onToggleFlag: () {
              setState(() {
                _flagged[_currentQuestionIndex] =
                    !(_flagged[_currentQuestionIndex] ?? false);
              });
              _updateSidebar();
            },
            onOptionSelected: (index, optionId) {
              setState(() {
                _selectedAnswers[index] = optionId;
              });
              _updateSidebar();
            },
            onSaveSession: () {},
            onPrevious: _currentQuestionIndex > 0
                ? () {
                    setState(() {
                      _currentQuestionIndex--;
                    });
                    _updateSidebar();
                  }
                : null,
            onNext: () {
              if (_currentQuestionIndex <
                  _exam!.questions.length - 1) {
                setState(() {
                  _currentQuestionIndex++;
                });
                _updateSidebar();
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
