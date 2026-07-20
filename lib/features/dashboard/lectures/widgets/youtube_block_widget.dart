import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/utils/video_utils.dart';
import 'package:arabilogia/features/dashboard/lectures/models/lecture.dart';
import 'package:go_router/go_router.dart';

class YoutubeBlockWidget extends StatelessWidget {
  final LectureContentBlock block;
  final bool isCompleted;
  final VoidCallback onToggleCompletion;

  const YoutubeBlockWidget({
    super.key,
    required this.block,
    required this.isCompleted,
    required this.onToggleCompletion,
  });

  @override
  Widget build(BuildContext context) {
    final url = block.content;
    final videoId = getVideoId(url);
    final title = block.metadata?['title'] ?? 'فيديو الشرح للمحاضرة';
    final duration = block.metadata?['duration'] ?? '56:59';

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (videoId.isNotEmpty)
            GestureDetector(
              onTap: () async {
                context.pushNamed(
                  'youtube-player',
                  extra: {'videoId': videoId, 'title': title},
                );
                if (!isCompleted) {
                  onToggleCompletion();
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, _, __) => Container(color: Colors.grey.shade200),
                  ),
                  Container(
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
                  const Icon(
                    Icons.play_circle_fill,
                    color: AppColors.primary,
                    size: 64,
                  ),
                  Positioned(
                    bottom: AppTokens.spacing8,
                    left: AppTokens.spacing8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        duration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                      const Text(
                        'شرح بالفيديو للمحاضرة',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onToggleCompletion,
                  icon: Icon(
                    isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isCompleted ? Colors.green : Colors.grey,
                  ),
                  label: Text(
                    isCompleted ? 'تمت المشاهدة' : 'حدد كمشاهد',
                    style: TextStyle(
                      color: isCompleted ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
