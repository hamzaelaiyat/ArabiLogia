import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/utils/video_utils.dart';
import 'package:arabilogia/features/dashboard/lectures/models/lecture.dart';

class YoutubeBlockWidget extends StatefulWidget {
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
  State<YoutubeBlockWidget> createState() => _YoutubeBlockWidgetState();
}

class _YoutubeBlockWidgetState extends State<YoutubeBlockWidget> {
  YoutubePlayerController? _controller;
  Timer? _positionTimer;

  String get _videoId => getVideoId(widget.block.content);

  Future<void> _mountPlayer() async {
    if (_controller != null || _videoId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final lastPosition = prefs.getInt('yt_$_videoId') ?? 0;
    if (!mounted) return;
    setState(() {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: _videoId,
        autoPlay: true,
        startSeconds: lastPosition > 3 ? lastPosition.toDouble() : null,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          strictRelatedVideos: true,
        ),
      );
    });
    _positionTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _savePosition(),
    );
    if (!widget.isCompleted) {
      widget.onToggleCompletion();
    }
  }

  Future<void> _savePosition() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final position = await controller.currentTime;
      if (position <= 0) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('yt_$_videoId', position.round());
    } catch (_) {}
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.block.content);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    unawaited(_savePosition());
    _controller?.close();
    super.dispose();
  }

  Widget _buildThumbnail(String duration) {
    return GestureDetector(
      onTap: _mountPlayer,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://img.youtube.com/vi/$_videoId/hqdefault.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) =>
                  Container(color: Colors.grey.shade200),
            ),
            Container(color: Colors.black.withValues(alpha: 0.2)),
            const Icon(
              Icons.play_circle_fill,
              color: AppColors.primary,
              size: 64,
            ),
            Positioned(
              bottom: AppTokens.spacing8,
              left: AppTokens.spacing8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.block.metadata?['title'] ?? 'فيديو الشرح للمحاضرة';
    final rawDuration = widget.block.metadata?['duration']?.toString() ?? '';
    final duration = rawDuration.isEmpty ? 'غير محدد' : rawDuration;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: AppTokens.radiusLgAll),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_controller != null)
            YoutubePlayer(controller: _controller!, aspectRatio: 16 / 9)
          else if (_videoId.isNotEmpty)
            _buildThumbnail(duration),
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
                IconButton(
                  tooltip: 'فتح في يوتيوب',
                  onPressed: _openExternally,
                  icon: Icon(
                    Icons.open_in_new,
                    size: AppTokens.iconSizeXs,
                    color: AppColors.mutedColor(context),
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onToggleCompletion,
                  icon: Icon(
                    widget.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: widget.isCompleted ? Colors.green : Colors.grey,
                  ),
                  label: Text(
                    widget.isCompleted ? 'تمت المشاهدة' : 'حدد كمشاهد',
                    style: TextStyle(
                      color: widget.isCompleted ? Colors.green : Colors.grey,
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
