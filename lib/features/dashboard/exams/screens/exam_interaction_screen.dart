import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_session.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/features/dashboard/exams/services/exam_session_service.dart';
import 'package:arabilogia/features/dashboard/exams/providers/exam_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/features/dashboard/exams/utils/score_calculator.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exam_interaction_body.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exam_timer.dart';
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
  DateTime? _backgroundTimestamp;

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
      _backgroundTimestamp = DateTime.now();
      _saveSession();
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundTimestamp != null && _exam != null) {
        _deductBackgroundTime();
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

  void _deductBackgroundTime() {
    final elapsed = DateTime.now().difference(_backgroundTimestamp!).inSeconds;
    _backgroundTimestamp = null;
    if (elapsed > 0) {
      _timerNotifier.value = (_timerNotifier.value - elapsed).clamp(0, _timerNotifier.value);
    }
    if (_timerNotifier.value <= 0) {
      _submitExam();
    }
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

    final scoreResult = calculateScore(
      questions: _exam!.questions,
      selectedAnswers: _selectedAnswers,
      remainingSeconds: _timerNotifier.value,
      totalDurationSeconds: (_exam!.durationMinutes ?? 30) * 60,
    );

    final correctCount = scoreResult.correctCount;
    final accuracy = scoreResult.accuracy;
    final speedBonus = scoreResult.speedBonus;
    final finalScore = scoreResult.finalScore;
    final wrongAnswers = scoreResult.wrongAnswers;

    try {
      await _scoreRepository
          .submitScore(
            examId: widget.examId,
            subject: widget.subjectName,
            score: finalScore,
            points: correctCount,
            wrongAnswers: wrongAnswers,
            isCompleted: true,
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
    }

    if (!mounted) return;

    await _sessionService.clearSession();

    context.read<ExamProvider>().endExam();

    context.pushReplacementNamed(
      'exam-result',
      extra: {
        'exam': _exam,
        'userAnswers': _selectedAnswers,
        'score': finalScore.round(),
        'accuracy': accuracy.round(),
        'speedBonus': speedBonus.round(),
        'correctCount': correctCount,
        'isFirstAttempt': _isFirstAttempt,
      },
    );
  }

  Future<void> _submitAbandonedExam() async {
    final scoreResult = calculateScore(
      questions: _exam!.questions,
      selectedAnswers: _selectedAnswers,
    );

    final correctCount = scoreResult.correctCount;
    final accuracy = scoreResult.accuracy;
    final finalScore = scoreResult.finalScore;
    final wrongAnswers = scoreResult.wrongAnswers;

    try {
      await _scoreRepository
          .submitScore(
            examId: widget.examId,
            subject: widget.subjectName,
            score: finalScore,
            points: correctCount,
            wrongAnswers: wrongAnswers,
            isCompleted: false,
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
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
            onSaveSession: _saveSession,
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
          ),
        ),
      ),
    );
  }
}
