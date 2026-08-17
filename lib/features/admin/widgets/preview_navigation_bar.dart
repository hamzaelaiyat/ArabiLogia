import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class PreviewNavigationBar extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;
  final Color? categoryColor;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final bool isLast;

  const PreviewNavigationBar({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    this.categoryColor,
    this.onPrevious,
    required this.onNext,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = categoryColor ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          if (currentIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: onPrevious,
                child: const Text('السابق'),
              ),
            ),
          if (currentIndex > 0)
            const SizedBox(width: AppTokens.spacing16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: Text(isLast ? 'نهاية المعاينة' : 'التالي'),
            ),
          ),
        ],
      ),
    );
  }
}
