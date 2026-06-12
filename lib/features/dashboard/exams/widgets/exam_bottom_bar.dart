import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class ExamBottomBar extends StatelessWidget {
  final VoidCallback onPressed;
  final Color color;

  const ExamBottomBar({
    super.key,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final potato = context.watch<PotatoModeProvider>();
    final hasBlur = potato.blurEffectsEnabled;

    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text(
        'ابدأ الاختبار الآن',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTokens.spacing16,
        AppTokens.spacing16,
        AppTokens.spacing16,
        MediaQuery.of(context).padding.bottom + AppTokens.spacing16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
      ),
      child: hasBlur
          ? ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: button,
              ),
            )
          : button,
    );
  }
}
