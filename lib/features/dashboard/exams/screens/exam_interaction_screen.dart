import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_session.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/features/dashboard/exams/services/exam_session_service.dart';
import 'package:arabilogia/providers/exam_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
    // First check for saved session
    final savedSession = await _sessionService.getSession();

    // Load exam based on subject ID and exam ID
    final exam = await _repository.loadExamById(
      widget.subjectId,
      widget.examId,
    );

    if (!mounted) return;

    if (exam != null) {
      if (mounted) {
        context.read<ExamProvider>().startExam();
        final localScores = await _scoreRepository.getLocalScores();

        // Shuffle questions (but preserve order if restoring session)
        if (savedSession != null && savedSession.examId == widget.examId) {
          // This is a restored session - keep original order and original question objects
          _isRestoredSession = true;
          setState(() {
            _isFirstAttempt = !localScores.containsKey(widget.examId);
            _exam =
                exam; // Use original exam directly to preserve question/option object references

            // Restore session if available
            _selectedAnswers.addAll(savedSession.selectedAnswers);
            _timerNotifier.value = savedSession.getRemainingSeconds();
            _isLoading = false;
          });

          // Clear saved session since we've restored it
          await _sessionService.clearSession();
        } else {
          final shuffledQuestions = (List<Question>.from(
            exam.questions,
          )..shuffle()).map((q) => q.shuffled()).toList();

          setState(() {
            _isFirstAttempt = !localScores.containsKey(widget.examId);
            _exam = exam.copyWith(questions: shuffledQuestions);

            // Restore session if available
            if (savedSession != null && savedSession.examId == widget.examId) {
              _selectedAnswers.addAll(savedSession.selectedAnswers);
              _timerNotifier.value = savedSession.getRemainingSeconds();
            } else {
              _timerNotifier.value = (exam.durationMinutes ?? 30) * 60;
            }
            _isLoading = false;
          });
        }
      } // end if (mounted)
    } else {
      // Fallback or error state
      context.pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('خطأ في تحميل الامتحان')));
    }
  }

  // Removed old _startTimer method as it was moved to ExamTimer widget

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

    // US-10: Speed Bonus
    double speedBonus = 0;
    if (accuracy >= 60) {
      final totalSeconds = (_exam!.durationMinutes ?? 30) * 60;
      final remainingSeconds = _timerNotifier.value;
      speedBonus = (remainingSeconds / totalSeconds) * 10;
    }

    final finalScore = (accuracy + speedBonus).clamp(0.0, 100.0);

    try {
      // Save to Supabase (Success or failure, we want to proceed to results)
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

    // Clear saved session since exam completed
    await _sessionService.clearSession();

    // End exam state before navigating
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
    // Calculate partial score for abandoned exam
    int answered = 0;
    int correctCount = 0;
    final List<String> wrongAnswers = [];

    for (int i = 0; i < _exam!.questions.length; i++) {
      if (_selectedAnswers.containsKey(i)) {
        answered++;
        // Find the selected option ID and check if it's the correct one
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
            isCompleted: false, // Mark as abandoned
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

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
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
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('خروج على أي حال'),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQuestion = _exam!.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _exam!.questions.length;
    final category = CategoryMetadata.getByName(_exam!.subject);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          // Submit score as abandoned (not completed) before exiting
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
              // Progress Bar
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
                      // Passage Card (if exists)
                      if (currentQuestion.passage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppTokens.spacing16),
                          decoration: BoxDecoration(
                            color: AppColors.surface(context),
                            borderRadius: AppTokens.radiusLgAll,
                            border: Border.all(
                              color: (category?.color ?? AppColors.primary)
                                  .withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            currentQuestion.passage!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  height: 1.8,
                                  color: AppColors.foreground(context),
                                ),
                          ),
                        ),
                        const SizedBox(height: AppTokens.spacing24),
                      ],

                      // Question Section
                      Text(
                        'السؤال ${_currentQuestionIndex + 1} من ${_exam!.questions.length}',
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

                      // Options
                      ...currentQuestion.options.map((option) {
                        final isSelected =
                            _selectedAnswers[_currentQuestionIndex] ==
                            option.id;
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
                              // Save session on each answer change
                              _saveSession();
                            },
                            borderRadius: AppTokens.radiusLgAll,
                            child: Container(
                              padding: const EdgeInsets.all(
                                AppTokens.spacing16,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (category?.color ?? AppColors.primary)
                                          .withValues(alpha: 0.1)
                                    : AppColors.surface(context),
                                borderRadius: AppTokens.radiusLgAll,
                                border: Border.all(
                                  color: isSelected
                                      ? (category?.color ?? AppColors.primary)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? (category?.color ??
                                                  AppColors.primary)
                                            : AppColors.mutedColor(context),
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                    (category?.color ??
                                                    AppColors.primary),
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: AppTokens.spacing12),
                                  Expanded(
                                    child: Text(
                                      option.text,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
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

              // Bottom Navigation
              Container(
                padding: const EdgeInsets.all(AppTokens.spacing16),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  border: Border(
                    top: BorderSide(
                      color:
                          DividerTheme.of(context).color ??
                          Colors.grey.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (_currentQuestionIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _currentQuestionIndex--;
                            });
                          },
                          child: const Text('السابق'),
                        ),
                      ),
                    if (_currentQuestionIndex > 0)
                      const SizedBox(width: AppTokens.spacing16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed:
                            _selectedAnswers[_currentQuestionIndex] == null
                            ? null
                            : () {
                                if (_currentQuestionIndex <
                                    _exam!.questions.length - 1) {
                                  setState(() {
                                    _currentQuestionIndex++;
                                  });
                                } else {
                                  if (!_isSubmitting) _submitExam();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: category?.color ?? AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _currentQuestionIndex <
                                        _exam!.questions.length - 1
                                    ? 'التالي'
                                    : 'إنهاء الاختبار',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExamTimer extends StatefulWidget {
  final ValueNotifier<int> timerNotifier;
  final VoidCallback onTimerEnd;

  const ExamTimer({
    super.key,
    required this.timerNotifier,
    required this.onTimerEnd,
  });

  @override
  State<ExamTimer> createState() => _ExamTimerState();
}

class _ExamTimerState extends State<ExamTimer> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _timer?.cancel(); // PAUSE timer when app goes to background
    } else if (state == AppLifecycleState.resumed) {
      _startTimer(); // RESTART timer when app resumes
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.timerNotifier.value > 0) {
        if (mounted) {
          widget.timerNotifier.value--;
        }
      } else {
        _timer?.cancel();
        widget.onTimerEnd();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: AppTokens.radiusFullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: AppColors.error),
          const SizedBox(width: 4),
          ValueListenableBuilder<int>(
            valueListenable: widget.timerNotifier,
            builder: (context, seconds, child) {
              return Text(
                _formatTime(seconds),
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
