import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
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
  Set<String> _completedBlockIds = {};
  List<Map<String, dynamic>> _parsedBlocks = [];

  @override
  void initState() {
    super.initState();
    _loadDataAndProgress();
  }

  @override
  void didUpdateWidget(covariant LectureCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lecture['id'] != widget.lecture['id']) {
      _loadDataAndProgress();
    }
  }

  Future<void> _loadDataAndProgress() async {
    final blocks = _parseBlocks(widget.lecture);
    final id = widget.lecture['id']?.toString() ?? '';
    Set<String> completedIds = {};

    if (id.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('lecture_progress_$id') ?? [];
      completedIds = list.toSet();
    }

    if (!mounted) return;
    setState(() {
      _parsedBlocks = blocks;
      _completedBlockIds = completedIds;
    });
  }

  static List<Map<String, dynamic>> _parseBlocks(Map<String, dynamic> lecture) {
    final List<Map<String, dynamic>> result = [];
    try {
      final raw = lecture['content_blocks'];
      if (raw != null) {
        final decoded = raw is String ? jsonDecode(raw) : raw;
        List<dynamic>? list;
        if (decoded is Map) {
          list = decoded['blocks'] as List<dynamic>?;
        } else if (decoded is List) {
          list = decoded;
        }

        if (list != null && list.isNotEmpty) {
          for (int i = 0; i < list.length; i++) {
            final b = list[i];
            if (b is Map) {
              result.add(Map<String, dynamic>.from(b));
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Silently caught error: $e");
    }

    // Fallback: If no structured blocks exist, construct blocks from legacy fields
    if (result.isEmpty) {
      final desc = lecture['description'] as String? ?? '';
      final yt = lecture['youtube_url'] as String? ?? '';
      final quiz = lecture['quiz_id'] as String?;

      if (yt.isNotEmpty) {
        result.add({
          'id': 'legacy_yt',
          'type': 'youtube',
          'content': yt,
          'metadata': {'duration_minutes': 20},
        });
      }
      if (desc.isNotEmpty) {
        final wordCount = desc.split(RegExp(r'\s+')).length;
        final minutes = (wordCount / 50).ceil().clamp(2, 15);
        result.add({
          'id': 'legacy_desc',
          'type': 'text',
          'content': desc,
          'metadata': {'duration_minutes': minutes},
        });
      }
      if (quiz != null && quiz.isNotEmpty) {
        result.add({
          'id': 'legacy_quiz',
          'type': 'quiz',
          'content': quiz,
          'metadata': {'duration_minutes': 10},
        });
      }
    }

    // Default block if lecture is completely empty
    if (result.isEmpty) {
      result.add({
        'id': 'default_block',
        'type': 'text',
        'content': 'محتوى المحاضرة',
        'metadata': {'duration_minutes': 15},
      });
    }

    return result;
  }

  // Calculate duration in minutes for a single block
  int _getBlockDurationMinutes(Map<String, dynamic> block) {
    final meta = block['metadata'];
    if (meta is Map) {
      final dur = meta['duration_minutes'] ?? meta['duration'];
      if (dur is num && dur > 0) return dur.toInt();
    }
    final type = block['type'] as String? ?? 'text';
    if (type == 'youtube') return 20;
    if (type == 'quiz' || type == 'exam') return 10;
    final content = block['content'] as String? ?? '';
    final words = content.split(RegExp(r'\s+')).length;
    return (words / 50).ceil().clamp(3, 15);
  }

  // Calculate TOTAL TIME of the lecture in minutes
  int get _totalMinutes {
    final explicitDur = widget.lecture['duration_minutes'] as num?;
    if (explicitDur != null && explicitDur > 0) {
      return explicitDur.toInt();
    }
    int sum = 0;
    for (final b in _parsedBlocks) {
      sum += _getBlockDurationMinutes(b);
    }
    return sum > 0 ? sum : 25;
  }

  // Calculate REMAINING TIME to complete the lecture in minutes
  int get _remainingMinutes {
    int uncompletedSum = 0;
    for (final b in _parsedBlocks) {
      final id = b['id']?.toString() ?? '';
      if (!_completedBlockIds.contains(id)) {
        uncompletedSum += _getBlockDurationMinutes(b);
      }
    }
    return uncompletedSum;
  }

  // Calculate COMPLETION PERCENTAGE from completed blocks
  int get _completionPercentage {
    if (_parsedBlocks.isEmpty) return 0;
    int completedCount = 0;
    for (final b in _parsedBlocks) {
      final id = b['id']?.toString() ?? '';
      if (_completedBlockIds.contains(id)) {
        completedCount++;
      }
    }
    return ((completedCount / _parsedBlocks.length) * 100).round().clamp(
      0,
      100,
    );
  }

  String _formatTotalTime(int totalMins) {
    if (totalMins >= 60) {
      final hours = totalMins ~/ 60;
      final mins = totalMins % 60;
      if (mins == 0) return '~$hoursساعة';
      return '~$hoursس $minsد';
    }
    return '~$totalMinsد';
  }

  String _formatRemainingTime(int remMins, int pct) {
    if (pct >= 100 || remMins <= 0) {
      return 'مكتملة';
    }
    if (remMins >= 60) {
      final hours = remMins ~/ 60;
      final mins = remMins % 60;
      if (mins == 0) return 'متبقي ~$hoursس';
      return 'متبقي ~$hoursس $minsد';
    }
    return 'متبقي ~$remMinsد';
  }

  String get _videoId {
    final direct = getVideoId(widget.lecture['youtube_url']?.toString() ?? '');
    if (direct.isNotEmpty) return direct;
    for (final b in _parsedBlocks) {
      if (b['type'] == 'youtube') {
        final vid = getVideoId(b['content']?.toString() ?? '');
        if (vid.isNotEmpty) return vid;
      }
    }
    return '';
  }

  Widget _thumbnailWidget(double width, double height) {
    final customThumbnail = widget.lecture['thumbnail_url']?.toString() ?? '';
    if (customThumbnail.isNotEmpty) {
      if (customThumbnail.startsWith('data:image')) {
        try {
          final bytes = base64Decode(customThumbnail.split(',').last);
          return SizedBox(
            width: width,
            height: height,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _youtubeOrPlaceholder(width, height),
            ),
          );
        } catch (e) {
          debugPrint("Silently caught error: $e");
        }
      }
      return SizedBox(
        width: width,
        height: height,
        child: Image.network(
          customThumbnail,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _youtubeOrPlaceholder(width, height),
        ),
      );
    }
    return _youtubeOrPlaceholder(width, height);
  }

  Widget _youtubeOrPlaceholder(double width, double height) {
    final vid = _videoId;
    return SizedBox(
      width: width,
      height: height,
      child: vid.isNotEmpty
          ? Image.network(
              'https://img.youtube.com/vi/$vid/hqdefault.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(width, height),
            )
          : _placeholder(width, height),
    );
  }

  Widget _placeholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: widget.categoryColor.withValues(alpha: 0.15),
      child: Icon(
        Icons.play_circle_outline,
        color: widget.categoryColor,
        size: 36,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = AppTokens.isDesktop(context);

    final pct = _completionPercentage;
    final totalTimeStr = _formatTotalTime(_totalMinutes);
    final remTimeStr = _formatRemainingTime(_remainingMinutes, pct);

    final cardBg = isDark ? AppColors.secondaryDark : const Color(0xFFE5F3FF);

    final titleText = widget.lecture['title'] as String? ?? 'شرح المحاضرة';

    if (isDesktop) {
      return _buildDesktopCard(
        context,
        cardBg,
        isDark,
        titleText,
        totalTimeStr,
        remTimeStr,
        pct,
      );
    } else {
      return _buildMobileCard(
        context,
        cardBg,
        isDark,
        titleText,
        totalTimeStr,
        remTimeStr,
        pct,
      );
    }
  }

  Widget _buildDesktopCard(
    BuildContext context,
    Color cardBg,
    bool isDark,
    String titleText,
    String totalTimeStr,
    String remTimeStr,
    int pct,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing16),
      height: 115,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Row(
            children: [
              SizedBox(
                width: 170,
                height: double.infinity,
                child: _thumbnailWidget(170, double.infinity),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        titleText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            totalTimeStr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.mutedDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Text(
                            remTimeStr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.mutedDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildDesktopPillGauge(pct),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopPillGauge(int pct) {
    final fillRatio = (pct / 100.0).clamp(0.0, 1.0);

    return Container(
      width: 58,
      height: 85,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(29),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (pct > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: (85 * fillRatio).clamp(4.0, 85.0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.blue, Color(0xFF1968D2)],
                  ),
                ),
              ),
            ),
          Text(
            '$pct%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCard(
    BuildContext context,
    Color cardBg,
    bool isDark,
    String titleText,
    String totalTimeStr,
    String remTimeStr,
    int pct,
  ) {
    final mobileBg = isDark ? AppColors.cardDark : const Color(0xFF97CBFF);
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtextColor = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF1E293B);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing12),
      height: 82,
      decoration: BoxDecoration(
        color: mobileBg,
        borderRadius: BorderRadius.circular(36),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF97CBFF).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(36),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                height: double.infinity,
                child: _thumbnailWidget(110, double.infinity),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        titleText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$totalTimeStr • $remTimeStr',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: subtextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
