import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/lectures/models/lecture.dart';
import 'package:go_router/go_router.dart';

class QuizBlockWidget extends StatelessWidget {
  final LectureContentBlock block;
  final bool isCompleted;
  final Map<String, Map<String, dynamic>> examScores;
  final String lectureCourseId;
  final String lectureId;
  final String categoryName;
  final VoidCallback onToggleCompletion;
  final VoidCallback onScoreRefresh;

  const QuizBlockWidget({
    super.key,
    required this.block,
    required this.isCompleted,
    required this.examScores,
    required this.lectureCourseId,
    required this.lectureId,
    required this.categoryName,
    required this.onToggleCompletion,
    required this.onScoreRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final examId = block.content;
    final title = block.metadata?['title'] ?? 'اختبار المحاضرة';
    final scoreData = examScores[examId];
    final hasAttempted = scoreData != null;
    final score = hasAttempted ? (scoreData['score'] as num).toDouble() : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          await context.pushNamed(
            'practice-quiz',
            pathParameters: {
              'examId': examId,
              'subjectId': lectureCourseId,
              'subjectName': categoryName,
              'lectureId': lectureId,
            },
          );

          if (!isCompleted) {
            onToggleCompletion();
          }
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
                child: const Icon(Icons.assignment, color: AppColors.primary),
              ),
              const SizedBox(width: AppTokens.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasAttempted)
                      Text(
                        'أعلى درجة محققة: ${score.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: score >= 85 ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      )
                    else
                      const Text(
                        'لم يتم خوض الاختبار القصير بعد',
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
