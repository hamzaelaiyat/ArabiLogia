import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';

class ExamInstructionsSection extends StatelessWidget {
  final String subjectName;
  final int? durationMinutes;
  final String subjectId;

  const ExamInstructionsSection({
    super.key,
    required this.subjectName,
    required this.durationMinutes,
    required this.subjectId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'الوصف'),
        const SizedBox(height: AppTokens.spacing8),
        Text(
          'يتناول هذا الاختبار مهارات $subjectName المقررة. تأكد من مراجعة الدروس جيداً قبل البدء.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.mutedColor(context),
            height: 1.6,
          ),
        ),
        const SizedBox(height: AppTokens.spacing24),
        _buildSectionTitle(context, 'تعليمات هامة'),
        const SizedBox(height: AppTokens.spacing12),
        _buildInstructionItem(context, 'تأكد من استقرار اتصال الإنترنت.'),
        _buildInstructionItem(
          context,
          'لديك $durationMinutes دقيقة فقط لإنهاء الاختبار.',
        ),
        _buildInstructionItem(
          context,
          'بمجرد البدء، لا يمكنك إيقاف المؤقت أو الخروج من الامتحان.',
        ),
        _buildInstructionItem(
          context,
          'سيتم احتساب الدرجة من المحاولة الأولى فقط (للمتصدرين).',
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInstructionItem(BuildContext context, String text) {
    final color = CategoryMetadata.categories
        .firstWhere((c) => c.id == subjectId)
        .color;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: color),
          const SizedBox(width: AppTokens.spacing8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
