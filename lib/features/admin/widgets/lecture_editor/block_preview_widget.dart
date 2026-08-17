import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:arabilogia/core/utils/video_utils.dart';
import 'package:arabilogia/features/dashboard/lectures/models/lecture.dart';

class BlockPreviewWidget extends StatelessWidget {
  final LectureContentBlock block;
  final VoidCallback? onEdit;

  const BlockPreviewWidget({
    super.key,
    required this.block,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case BlockType.text:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: MarkdownBody(
            data: block.content,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
          ),
        );
      case BlockType.youtube:
        final videoId = getVideoId(block.content);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(block.content, style: const TextStyle(color: Colors.blue, fontSize: 12)),
            const SizedBox(height: 8),
            if (videoId.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => Container(
                        height: 160,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.movie_creation_outlined, size: 50, color: Colors.grey),
                      ),
                    ),
                    Container(
                      height: 160,
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                    const Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 64,
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: Colors.black87,
                        child: Text(
                          block.metadata?['duration'] ?? '56:59',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    )
                  ],
                ),
              ),
          ],
        );
      case BlockType.exam:
      case BlockType.quiz:
        final qCount = block.metadata?['questionsCount'] ?? 0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange.shade300),
            color: Colors.orange.shade50.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    block.metadata?['title'] ?? 'اختبار قصير',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Chip(
                    label: Text('اختبار قصير بدون نقاط', style: TextStyle(color: Colors.orange, fontSize: 12)),
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('عدد الأسئلة: $qCount أسئلة'),
              const Text('بدون وقت محدد'),
              const SizedBox(height: 12),
              if (onEdit != null)
                ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('تعديل أسئلة الاختبار القصير'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        );
    }
  }
}
