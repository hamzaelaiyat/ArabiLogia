import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class ExamEmptyState extends StatelessWidget {
  const ExamEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 64,
            color: AppColors.mutedColor(context).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد امتحانات متاحة حالياً',
            style: TextStyle(color: AppColors.mutedColor(context)),
          ),
          Text(
            'ترقبونا قريباً!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedColor(context).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
