import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class ExamFlipTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const ExamFlipTransition({
    super.key,
    required this.child,
    this.duration = AppTokens.durationSm,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppTokens.curveDefault,
      switchOutCurve: AppTokens.curveDefault,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
