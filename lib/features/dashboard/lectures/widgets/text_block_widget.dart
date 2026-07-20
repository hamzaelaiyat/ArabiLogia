import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/lectures/models/lecture.dart';

class TextBlockWidget extends StatelessWidget {
  final LectureContentBlock block;
  final bool isCompleted;
  final VoidCallback onToggleCompletion;

  const TextBlockWidget({
    super.key,
    required this.block,
    required this.isCompleted,
    required this.onToggleCompletion,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MarkdownBody(
              data: block.content,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.7,
                      fontSize: 16,
                    ),
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onToggleCompletion,
                  icon: Icon(
                    isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isCompleted ? Colors.green : Colors.grey,
                  ),
                  label: Text(
                    isCompleted ? 'تم القراءة' : 'تحديد كمقروء',
                    style: TextStyle(
                      color: isCompleted ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
