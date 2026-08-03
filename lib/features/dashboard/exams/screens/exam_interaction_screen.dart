import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/services/screen_capture_service.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
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
  final ScreenCaptureService _screenCapture = ScreenCaptureService();
  Exam? _exam;
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  final Map<int, String?> _selectedAnswers = {};
  late ValueNotifier<int> _timerNotifier;
  bool _isSubmitting = false;
  bool _isFirstAttempt = true;
  DateTime? _backgroundTimestamp;
  // In-memory only; server anchors the speed bonus.
  String? _serverSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timerNotifier = ValueNotifier<int>(0);
    _screenCapture.enableSecureMode();
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
      _timerNotifier.value =
          (_timerNotifier.value - elapsed).clamp(0, _timerNotifier.value);
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

    if (exam == null) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ في تحميل الامتحان')),
      );
      return;
    }

    final localScores = await _scoreRepository.getLocalScores();
    context.read<ExamProvider>().startExam();

    final ExamSession? restoredSession =
        savedSession != null && savedSession.examId == widget.examId
            ? savedSession
            : null;

    final shuffledQuestions = (List<Question>.from(exam.questions)..shuffle())
        .map((q) => q.shuffled())
        .toList();

    // Start a server session unless we're resuming one we already own.
    if (restoredSession == null) {
      final startInfo = await _scoreRepository.startExam(widget.examId);
      _serverSessionId = startInfo?.sessionId;
    }

    if (!mounted) return;

    setState(() {
      _isFirstAttempt = !localScores.containsKey(widget.examId);
      _exam = exam.copyWith(questions: shuffledQuestions);

      if (restoredSession != null) {
        _selectedAnswers.addAll(restoredSession.selectedAnswers);
        _timerNotifier.value = restoredSession.getRemainingSeconds();
      } else {
        _timerNotifier.value = (exam.durationMinutes ?? 30) * 60;
      }
      _isLoading = false;
    });
  }

  Future<void> _submitExam() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final result = await _scoreRepository
          .submitExamAnswer(
            examId: widget.examId,
            answers: _selectedAnswers,
            sessionId: _serverSessionId,
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إرسال الإجابات، حاول مرة أخرى')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      await _sessionService.clearSession();
      context.read<ExamProvider>().endExam();

      // Pull the answer key so the result screen can highlight the
      // correct option for each question.
      final review = await _scoreRepository.getExamReview(widget.examId);
      if (!mounted) return;

      final reviewExam = review == null
          ? _exam!
          : Exam.fromMinifiedJson(review.data).applyAnswers(review.answers);

      context.pushReplacementNamed(
        'exam-result',
        extra: {
          'exam': reviewExam,
          'userAnswers': _selectedAnswers,
          'score': result.score.round(),
          'accuracy': result.accuracy.round(),
          'speedBonus': result.speedBonus.round(),
          'correctCount': result.correctCount,
          'isFirstAttempt': _isFirstAttempt,
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitAbandonedExam() async {
    await _sessionService.clearSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _screenCapture.disableSecureMode();
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

    return ValueListenableBuilder<bool>(
      valueListenable: _screenCapture.isCaptured,
      builder: (context, isCaptured, child) {
        return Stack(
          children: [
            child!,
            if (isCaptured)
              const Positioned.fill(
                child: ColoredBox(
                  color: AppColors.bgDark,
                  child: Center(
                    child: Icon(Icons.screen_lock_portrait,
                        color: Colors.white54, size: 64),
                  ),
                ),
              ),
          ],
        );
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await showExitConfirmationDialog(context);
          if (shouldPop && context.mounted) {
            await _submitAbandonedExam();
            if (!context.mounted) return;
            context.read<ExamProvider>().endExam();
            context.pop();
          }
        },
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            key: TestKeys.examInteractionScreen,
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
                if (_currentQuestionIndex < _exam!.questions.length - 1) {
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
      ),
    );
  }
}
