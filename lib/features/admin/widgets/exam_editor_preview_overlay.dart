import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';
import 'package:arabilogia/features/admin/widgets/exam_editor_preview.dart';

class ExamPreviewOverlay extends StatelessWidget {
  final bool isVisible;
  final bool isDesktop;
  final List<Question> questions;
  final List<QuestionSettings> questionSettings;
  final VoidCallback onClose;

  const ExamPreviewOverlay({
    super.key,
    required this.isVisible,
    required this.isDesktop,
    required this.questions,
    required this.questionSettings,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final bgColor = AppColors.background(context);
    final fgColor = AppColors.foreground(context);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.black54),
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 800 : double.infinity,
              maxHeight: 600,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'معاينة الامتحان',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: fgColor,
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: Icon(Icons.close, color: fgColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ExamPreviewContent(
                    questions: questions,
                    questionSettings: questionSettings,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}