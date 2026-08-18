import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class ExamTimer extends StatefulWidget {
  final ValueNotifier<int> timerNotifier;
  final VoidCallback onTimerEnd;
  final ValueNotifier<String?>? warningNotifier;

  const ExamTimer({
    super.key,
    required this.timerNotifier,
    required this.onTimerEnd,
    this.warningNotifier,
  });

  @override
  State<ExamTimer> createState() => _ExamTimerState();
}

class _ExamTimerState extends State<ExamTimer>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _pulseController;
  bool _warned5 = false;
  bool _warned1 = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0,
    );
    widget.timerNotifier.addListener(_handleTimeChanged);
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _startTimer();
    }
  }

  void _handleTimeChanged() {
    final seconds = widget.timerNotifier.value;
    if (seconds <= 300 && seconds > 60 && !_warned5) {
      _warned5 = true;
      widget.warningNotifier?.value = 'باقي 5 دقائق';
    }
    if (seconds <= 60 && seconds > 0 && !_warned1) {
      _warned1 = true;
      widget.warningNotifier?.value = 'باقي دقيقة';
    }
    if (seconds <= 30 && seconds > 0) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else if (_pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }
  }

  void _startTimer() {
    _timer?.cancel();
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
    WidgetsBinding.instance.removeObserver(this);
    widget.timerNotifier.removeListener(_handleTimeChanged);
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _colorFor(int seconds) {
    if (seconds > 300) return AppColors.examPass;
    if (seconds > 60) return AppColors.examWarning;
    return AppColors.examFail;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.timerNotifier,
      builder: (context, seconds, child) {
        final color = _colorFor(seconds);
        final minutes = (seconds / 60).floor();
        final remaining = seconds % 60;
        return Semantics(
          label: 'الوقت المتبقي: $minutes دقيقة و $remaining ثانية',
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.4)
                .animate(_pulseController),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: AppTokens.radiusFullAll,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(seconds),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
