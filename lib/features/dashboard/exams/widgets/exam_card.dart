import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_level.dart';

class ExamCard extends StatelessWidget {
  final Map<String, dynamic> exam;
  final VoidCallback? onTap;
  final bool isLocked;
  final bool isCompleted;

  const ExamCard({
    super.key,
    required this.exam,
    this.onTap,
    this.isLocked = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final level = ExamLevel.fromValue(exam['level'] as int?);
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing8),
      child: Card(
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: AppTokens.radius2xlAll,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spacing12),
            child: Row(
              children: [
                const SizedBox(width: AppTokens.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exam['title'] as String,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: isLocked
                                        ? AppColors.mutedColor(context)
                                        : null,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 14,
                            color: AppColors.mutedColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${exam['questions']} سؤال',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: AppTokens.spacing12),
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: AppColors.mutedColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${exam['duration'] ?? 30} دقيقة',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: AppTokens.spacing12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: level.color.withValues(alpha: 0.1),
                              borderRadius: AppTokens.radiusSmAll,
                            ),
                            child: Text(
                              level.label,
                              style: TextStyle(
                                color: level.color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: AppTokens.radiusSmAll,
                    ),
                    child: Text(
                      '${exam['score']}%',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                else if (!isLocked)
                  Icon(
                    Icons.chevron_left,
                    color: AppColors.mutedColor(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
