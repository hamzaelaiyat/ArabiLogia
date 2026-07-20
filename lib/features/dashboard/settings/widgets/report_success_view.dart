import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/drag_handle.dart';

class ReportSuccessView extends StatelessWidget {
  const ReportSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const DragHandle(),
        const SizedBox(height: AppTokens.spacing24),
        const Icon(
          Icons.check_circle,
          size: 80,
          color: AppColors.success,
        ),
        const SizedBox(height: AppTokens.spacing24),
        Text(
          'تم إرسال التقرير بنجاح',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTokens.spacing8),
        Text(
          'شكراً لمساعدتنا في تحسين التطبيق، سنتعامل مع المشكلة في أقرب وقت.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedColor(context),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTokens.spacing24),
      ],
    );
  }
}
