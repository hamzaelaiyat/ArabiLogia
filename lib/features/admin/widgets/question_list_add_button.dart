import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class QuestionListAddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const QuestionListAddButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppTokens.radiusFullAll,
          boxShadow: AppTokens.shadowOutside,
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'إضافة سؤال جديد',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.2),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: const StadiumBorder(),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
