import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_session.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/features/dashboard/exams/services/exam_session_service.dart';
import 'package:arabilogia/providers/exam_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exam_timer.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/question_passage.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/question_option_tile.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exam_bottom_bar.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exit_confirmation_dialog.dart';

class ExamInteractionScreen extends StatefulWidget {
  final String examId;
  final String subjectId;
  final String subjectName;
  const ExamInteractionScreen({
    super.key,
    required this.examId,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<ExamInteractionScreen> createState() => _ExamInteractionScreenState();
}

class _ExamInteractionScreenState extends State<ExamInteractionScreen>
    with WidgetsBindingObserver {
  final ExamRepository _repository = ExamRepository();
  final ScoreRepository _scoreRepository = ScoreRepository();
  final ExamSessionService _sessionService = ExamSessionService();
  Exam? _exam;
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  final Map<int, String?> _selectedAnswers = {};
  late ValueNotifier<int> _timerNotifier;
  bool _isSubmitting = false;
  bool _isFirstAttempt = true;
  bool _isRestoredSession = false;
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timerNotifier = ValueNotifier<int>(0);
    _loadExam();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _wasInBackground = true;
      _saveSession();
    } else if (state == AppLifecycleState.resumed) {
      if (_wasInBackground && _exam != null) {
        _checkTimeExpiredWhileAway();
      }
    }
  }

  Future<void> _saveSession() async {
    if (_exam == null) return;
    final session = ExamSession(
      examId: widget.examId,
      examTitle: _exam!.title,
      durationMinutes: _exam!.durationMinutes ?? 30,
      startTimestamp:
          DateTime.now().millisecondsSinceEpoch -
          ((_exam!.durationMinutes ?? 30) * 60 * 1000 -
              _timerNotifier.value * 1000),
      selectedAnswers: Map.from(_selectedAnswers),
    );
    await _sessionService.saveSession(session);
  }

  void _checkTimeExpiredWhileAway() {
    final remaining = _timerNotifier.value;
    if (remaining <= 0) {
      _submitExam();
    }
    _wasInBackground = false;
  }

  Future<void> _loadExam() async {
    final savedSession = await _sessionService.getSession();

    final exam = await _repository.loadExamById(
      widget.subjectId,
      widget.examId,
    );

    if (!mounted) return;

    if (exam != null) {
      if (mounted) {
        context.read<ExamProvider>().startExam();
        final localScores = await _scoreRepository.getLocalScores();

        if (savedSession != null && savedSession.examId == widget.examId) {
          _isRestoredSession = true;
          setState(() {
            _isFirstAttempt = !localScores.containsKey(widget.examId);
            _exam = exam;

            _selectedAnswers.addAll(savedSession.selectedAnswers);
            _timerNotifier.value = savedSession.getRemainingSeconds();
            _isLoading = false;
          });

          await _sessionService.clearSession();
        } else {
          final shuffledQuestions = (List<Question>.from(
            exam.questions,
          )..shuffle()).map((q) => q.shuffled()).toList();

          setState(() {
            _isFirstAttempt = !localScores.containsKey(widget.examId);
            _exam = exam.copyWith(questions: shuffledQuestions);

            if (savedSession != null && savedSession.examId == widget.examId) {
              _selectedAnswers.addAll(savedSession.selectedAnswers);
              _timerNotifier.value = savedSession.getRemainingSeconds();
            } else {
              _timerNotifier.value = (exam.durationMinutes ?? 30) * 60;
            }
            _isLoading = false;
          });
        }
      }
    } else {
      context.pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('خطأ في تحميل الامتحان')));
    }
  }

  Future<void> _submitExam() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    int correctCount = 0;
    final List<String> wrongAnswers = [];
    for (int i = 0; i < _exam!.questions.length; i++) {
      final question = _exam!.questions[i];
      final selectedId = _selectedAnswers[i];
      final correctOption = question.options.firstWhere((o) => o.isCorrect);
      if (selectedId == correctOption.id) {
        correctCount++;
      } else {
        wrongAnswers.add(question.id);
      }
    }

    final totalCount = _exam!.questions.length;
    final accuracy = (correctCount / totalCount) * 100;

    double speedBonus = 0;
    if (accuracy >= 60) {
      final totalSeconds = (_exam!.durationMinutes ?? 30) * 60;
      final remainingSeconds = _timerNotifier.value;
      speedBonus = (remainingSeconds / totalSeconds) * 10;
    }

    final finalScore = (accuracy + speedBonus).clamp(0.0, 100.0);

    try {
      await _scoreRepository
          .submitScore(
            examId: widget.examId,
            subject: widget.subjectName,
            score: finalScore,
            wrongAnswers: wrongAnswers,
            isCompleted: true,
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Score Submission Error: $e');
    }

    if (!mounted) return;

    await _sessionService.clearSession();

    context.read<ExamProvider>().endExam();

    context.pushReplacementNamed(
      'exam-result',
      extra: {
        'exam': _exam,
        'userAnswers': _selectedAnswers,
        'score': finalScore.toInt(),
        'accuracy': accuracy.toInt(),
        'speedBonus': speedBonus.toInt(),
        'correctCount': correctCount,
        'isFirstAttempt': _isFirstAttempt,
      },
    );
  }

  Future<void> _submitAbandonedExam() async {
    int answered = 0;
    int correctCount = 0;
    final List<String> wrongAnswers = [];

    for (int i = 0; i < _exam!.questions.length; i++) {
      if (_selectedAnswers.containsKey(i)) {
        answered++;
        final selectedOptionId = _selectedAnswers[i];
        final correctOption = _exam!.questions[i].options.firstWhere(
          (o) => o.isCorrect,
        );
        if (selectedOptionId == correctOption.id) {
          correctCount++;
        } else {
          wrongAnswers.add(_exam!.questions[i].id);
        }
      }
    }

    final accuracy = _exam!.questions.isEmpty
        ? 0.0
        : ((correctCount / _exam!.questions.length) * 100);

    final finalScore = accuracy.clamp(0.0, 100.0);

    debugPrint(
      'Submitting abandoned exam: answered $answered/${_exam!.questions.length}, score $finalScore',
    );

    try {
      await _scoreRepository
          .submitScore(
            examId: widget.examId,
            subject: widget.subjectName,
            score: finalScore,
            wrongAnswers: wrongAnswers,
            isCompleted: false,
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Abandoned Score Submission Error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQuestion = _exam!.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _exam!.questions.length;
    final category = CategoryMetadata.getByName(_exam!.subject);
    final categoryColor = category?.color ?? AppColors.primary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showExitConfirmationDialog(context);
        if (shouldPop && context.mounted) {
          await _submitAbandonedExam();
          context.read<ExamProvider>().endExam();
          context.pop();
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Icon(category?.icon ?? Icons.quiz, color: category?.color),
                const SizedBox(width: 8),
                Text(_exam!.title, style: const TextStyle(fontSize: 16)),
              ],
            ),
            actions: [
              ExamTimer(timerNotifier: _timerNotifier, onTimerEnd: _submitExam),
            ],
          ),
          body: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surface(context),
                valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                minHeight: 6,
              ),
              Expanded(
                child: Column(
                  children: [
                    if (currentQuestion.passage != null)
                      Expanded(
                        flex: 2,
                        child: QuestionPassage(
                          passage: currentQuestion.passage!,
                          categoryColor: categoryColor,
                        ),
                      ),
                    if (currentQuestion.passage != null)
                      const SizedBox(height: AppTokens.spacing16),

                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'السؤال ${_currentQuestionIndex + 1} من ${_exam!.questions.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.mutedColor(context),
                                  ),
                            ),
                            const SizedBox(height: AppTokens.spacing8),
                            RichText(
                              text: TextSpan(
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                children: parseQuestionText(
                                  currentQuestion.text,
                                  isDark: Theme.of(context).brightness ==
                                      Brightness.dark,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTokens.spacing24),

                            ...currentQuestion.options.map((option) {
                              final isSelected =
                                  _selectedAnswers[_currentQuestionIndex] ==
                                      option.id;
                              return QuestionOptionTile(
                                option: option,
                                isSelected: isSelected,
                                categoryColor: categoryColor,
                                onTap: () {
                                  setState(() {
                                    _selectedAnswers[_currentQuestionIndex] =
                                        option.id;
                                  });
                                  _saveSession();
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              ExamBottomBar(
                currentQuestionIndex: _currentQuestionIndex,
                totalQuestions: _exam!.questions.length,
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
                    if (!_isSubmitting) _submitExam();
                  }
                },
                isSubmitting: _isSubmitting,
                hasSelectedAnswer:
                    _selectedAnswers[_currentQuestionIndex] != null,
                categoryColor: categoryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
