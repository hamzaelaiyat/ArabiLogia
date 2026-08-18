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
  bool _isPlaying = false;

  String get _videoId => getVideoId(widget.block.content);

  Future<void> _launchExternalVideo() async {
    if (_videoId.isEmpty) return;
    final uri = Uri.parse('https://www.youtube.com/watch?v=$_videoId');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _startPlaying() async {
    if (_videoId.isEmpty) return;

    if (_controller == null) {
      int lastPosition = 0;
      try {
        final prefs = await SharedPreferences.getInstance();
        lastPosition = prefs.getInt('yt_$_videoId') ?? 0;
      } catch (_) {}

      try {
        final controller = YoutubePlayerController.fromVideoId(
          videoId: _videoId,
          autoPlay: true,
          startSeconds: lastPosition > 3 ? lastPosition.toDouble() : null,
          params: const YoutubePlayerParams(
            showFullscreenButton: true,
            strictRelatedVideos: true,
            showControls: true,
          ),
        );

        if (!mounted) return;
        setState(() {
          _controller = controller;
          _isPlaying = true;
        });

        _positionTimer?.cancel();
        _positionTimer = Timer.periodic(
          const Duration(seconds: 5),
          (_) => _savePosition(),
        );

        if (!widget.isCompleted) {
          widget.onToggleCompletion();
        }
      } catch (e) {
        // Fallback to launching external browser / YouTube app when WebViewPlatform is unavailable
        await _launchExternalVideo();
      }
    } else {
      try {
        setState(() {
          _isPlaying = true;
        });
        _controller?.playVideo();
      } catch (_) {
        await _launchExternalVideo();
      }
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

  @override
  void dispose() {
    _positionTimer?.cancel();
    unawaited(_savePosition());
    _controller?.close();
    super.dispose();
  }

  Widget _buildVideoThumbnail(String duration) {
    return GestureDetector(
      onTap: _startPlaying,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://img.youtube.com/vi/$_videoId/hqdefault.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) => Container(
                color: Colors.grey.shade900,
                child: const Icon(Icons.video_library_rounded, color: Colors.white54, size: 48),
              ),
            ),
            Container(color: Colors.black.withValues(alpha: 0.3)),
            Center(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            if (duration.isNotEmpty)
              Positioned(
                bottom: AppTokens.spacing8,
                left: AppTokens.spacing8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Card(
          margin: const EdgeInsets.only(bottom: AppTokens.spacing16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: AppTokens.radiusLgAll),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isPlaying && _controller != null)
            YoutubePlayer(controller: _controller!, aspectRatio: 16 / 9)
          else if (_videoId.isNotEmpty)
            _buildVideoThumbnail(rawDuration)
          else
            Container(
              height: 180,
              color: Colors.grey.shade200,
              child: const Center(
                child: Text('رابط الفيديو غير صالح'),
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
                      InkWell(
                        onTap: _launchExternalVideo,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'فتح في يوتيوب',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
    ),
  ),
);
  }
}
