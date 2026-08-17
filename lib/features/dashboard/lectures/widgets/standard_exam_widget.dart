import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:go_router/go_router.dart';

class StandardExamWidget extends StatelessWidget {
  final Exam exam;
  final Map<String, Map<String, dynamic>> examScores;
  final String lectureCourseId;
  final String categoryName;
  final VoidCallback onScoreRefresh;

  const StandardExamWidget({
    super.key,
    required this.exam,
    required this.examScores,
    required this.lectureCourseId,
    required this.categoryName,
    required this.onScoreRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final examId = exam.id;
    final title = exam.title;
    final scoreData = examScores[examId];
    final hasAttempted = scoreData != null;
    final score = hasAttempted ? (scoreData['score'] as num).toDouble() : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          await context.pushNamed(
            'exam-interaction',
            pathParameters: {'id': examId},
            extra: {
              'subjectId': lectureCourseId,
              'subjectName': categoryName,
            },
          );
          onScoreRefresh();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: AppTokens.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.examPass.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'امتحان ختامي',
                            style: TextStyle(
                              color: AppColors.examPass,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exam.durationMinutes != null
                          ? '${exam.questions.length} سؤال · ${exam.durationMinutes} دقيقة'
                          : '${exam.questions.length} سؤال',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    if (hasAttempted)
                      Text(
                        'أعلى درجة محققة: ${score.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: score >= exam.passPercentage ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      )
                    else
                      const Text(
                        'لم يتم خوض الامتحان بعد',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (hasAttempted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${score.toStringAsFixed(0)}%',
                        style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_left, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
