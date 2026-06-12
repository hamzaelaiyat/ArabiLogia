import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class QuestionPassage extends StatelessWidget {
  final String passage;
  final Color categoryColor;

  const QuestionPassage({
    super.key,
    required this.passage,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppTokens.radiusLgAll,
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: AppTokens.radiusLgAll,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppTokens.spacing16),
          child: Text(
            passage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.8,
                  color: AppColors.foreground(context),
                ),
          ),
        ),
      ),
    );
  }
}
