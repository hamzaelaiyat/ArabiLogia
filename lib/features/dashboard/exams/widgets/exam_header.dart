import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';

class ExamHeader extends StatelessWidget {
  final String subjectName;
  final String subjectId;
  final String title;

  const ExamHeader({
    super.key,
    required this.subjectName,
    required this.subjectId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        CategoryMetadata.getById(subjectId)?.color ?? const Color(0xFFEB8A00);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: AppTokens.radiusFullAll,
          ),
          child: Text(
            subjectName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: AppTokens.spacing12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
