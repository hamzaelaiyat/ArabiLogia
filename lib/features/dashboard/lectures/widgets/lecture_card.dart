import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_text_styles.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/utils/video_utils.dart';

class LectureCard extends StatefulWidget {
  final Map<String, dynamic> lecture;
  final VoidCallback? onTap;
  final Color categoryColor;

  const LectureCard({
    super.key,
    required this.lecture,
    this.onTap,
    required this.categoryColor,
  });

  @override
  State<LectureCard> createState() => _LectureCardState();
}

class _LectureCardState extends State<LectureCard> {
  int _completedCount = 0;
  int _totalBlocks = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void didUpdateWidget(covariant LectureCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lecture['id'] != widget.lecture['id']) {
      _loadProgress();
    }
  }

  List<dynamic>? get _blocks {
    try {
      final raw = widget.lecture['content_blocks'];
      if (raw == null) return null;
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is Map) return decoded['blocks'] as List<dynamic>?;
      if (decoded is List) return decoded;
    } catch (_) {}
    return null;
  }

  Future<void> _loadProgress() async {
    final id = widget.lecture['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList('lecture_progress_$id') ?? [];
    if (!mounted) return;
    setState(() {
      _completedCount = completed.length;
      _totalBlocks = _blocks?.length ?? 0;
    });
  }

  String get _videoId {
    final direct = getVideoId(widget.lecture['youtube_url']?.toString() ?? '');
    if (direct.isNotEmpty) return direct;
    final blocks = _blocks;
    if (blocks != null) {
      for (final b in blocks) {
        if (b is Map && b['type'] == 'youtube') {
          final vid = getVideoId(b['content']?.toString() ?? '');
          if (vid.isNotEmpty) return vid;
        }
      }
    }
    return '';
  }

  double get _progress =>
      _totalBlocks == 0 ? 0 : (_completedCount / _totalBlocks).clamp(0.0, 1.0);

  Widget _placeholder() {
    return Container(
      color: widget.categoryColor.withValues(alpha: 0.12),
      child: Icon(
        Icons.play_circle_outline,
        color: widget.categoryColor,
        size: AppTokens.iconSizeLg,
      ),
    );
  }

  Widget _thumbnail() {
    final customThumbnail = widget.lecture['thumbnail_url']?.toString() ?? '';
    if (customThumbnail.isNotEmpty) {
      if (customThumbnail.startsWith('data:image')) {
        try {
          final bytes = base64Decode(customThumbnail.split(',').last);
          return SizedBox(
            width: 120,
            height: 72,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _youtubeOrPlaceholder(),
            ),
          );
        } catch (_) {}
      }
      return SizedBox(
        width: 120,
        height: 72,
        child: Image.network(
          customThumbnail,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _youtubeOrPlaceholder(),
        ),
      );
    }
    return _youtubeOrPlaceholder();
  }

  Widget _youtubeOrPlaceholder() {
    final vid = _videoId;
    return SizedBox(
      width: 120,
      height: 72,
      child: vid.isNotEmpty
          ? Image.network(
              'https://img.youtube.com/vi/$vid/hqdefault.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.lecture['description'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 4, color: widget.categoryColor),
                Padding(
                  padding: const EdgeInsets.all(AppTokens.spacing6),
                  child: ClipRRect(
                    borderRadius: AppTokens.radiusSmAll,
                    child: _thumbnail(),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTokens.spacing6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.lecture['title'] as String? ?? '',
                                style: Theme.of(context).textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.lecture['quiz_id'] != null) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.quiz_outlined,
                                size: 14,
                                color: widget.categoryColor,
                              ),
                            ],
                          ],
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (_totalBlocks > 0 && _completedCount > 0) ...[
                          const SizedBox(height: AppTokens.spacing4),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _progress,
                                    minHeight: 5,
                                    backgroundColor: widget.categoryColor
                                        .withValues(alpha: 0.15),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      widget.categoryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTokens.spacing4),
                              Text(
                                '${(_progress * 100).round()}%',
                                style: AppTextStyles.caption.copyWith(
                                  color: widget.categoryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spacing4,
                  ),
                  child: Icon(
                    Icons.chevron_left,
                    color: AppColors.mutedColor(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
