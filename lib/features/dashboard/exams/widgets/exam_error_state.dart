import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class ExamErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ExamErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: AppColors.error)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
