import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/lectures/repositories/lecture_repository.dart';
import 'package:arabilogia/features/dashboard/home/widgets/category_card.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/core/widgets/animated_wrapper.dart';
import 'package:arabilogia/core/utils/video_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ExamCategoriesGrid extends StatefulWidget {
  const ExamCategoriesGrid({super.key});

  @override
  State<ExamCategoriesGrid> createState() => _ExamCategoriesGridState();
}

class _ExamCategoriesGridState extends State<ExamCategoriesGrid> {
  final LectureRepository _lectureRepository = LectureRepository();

  Map<String, List<Map<String, dynamic>>> _categoryLectures = {};
  Map<String, int> _categoryCompleted = {};
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
  }

  Future<void> _loadCategoryData() async {
    final categories = CategoryMetadata.categories;

    try {
      // Fire all category fetches in parallel instead of sequentially
      final lectureResults = await Future.wait(
        categories.map(
          (cat) => _lectureRepository.getLecturesByCategory(cat.id),
        ),
      );

      // Single SharedPreferences read for all lectures
      final prefs = await SharedPreferences.getInstance();

      final Map<String, List<Map<String, dynamic>>> lecturesMap = {};
      final Map<String, int> completedMap = {};

      for (var i = 0; i < categories.length; i++) {
        final cat = categories[i];
        final lectures = lectureResults[i];
        lecturesMap[cat.id] = lectures;

        int completedCount = 0;
        for (final l in lectures) {
          final id = l['id']?.toString() ?? '';
          if (id.isEmpty) continue;
          final list = prefs.getStringList('lecture_progress_$id');
          if (list == null) continue;
          final blocksRaw = l['content_blocks'];
          int totalBlocks = 1;
          if (blocksRaw != null) {
            final decoded = blocksRaw is String
                ? jsonDecode(blocksRaw)
                : blocksRaw;
            if (decoded is Map && decoded['blocks'] is List) {
              totalBlocks = (decoded['blocks'] as List).length;
            } else if (decoded is List) {
              totalBlocks = decoded.length;
            }
          }
          if (list.length >= totalBlocks && totalBlocks > 0) {
            completedCount++;
          }
        }
        completedMap[cat.id] = completedCount;
      }

      if (mounted) {
        setState(() {
          _categoryLectures = lecturesMap;
          _categoryCompleted = completedMap;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load category lecture data: $e');
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  String? _getLatestThumbnail(List<Map<String, dynamic>>? lectures) {
    if (lectures == null || lectures.isEmpty) return null;
    final latest = lectures.first;

    // 1) Use explicit thumbnail_url if available
    final customThumbnail = latest['thumbnail_url'] as String?;
    if (customThumbnail != null && customThumbnail.trim().isNotEmpty) {
      return customThumbnail.trim();
    }

    // 2) Derive video ID from youtube_url or content_blocks
    final youtubeUrl = latest['youtube_url'] as String? ?? '';
    var videoId = getVideoId(youtubeUrl);
    if (videoId.isEmpty) {
      final blocks =
          latest['content_blocks'] as List? ?? latest['blocks'] as List?;
      if (blocks != null) {
        for (final b in blocks) {
          if (b is Map && b['type'] == 'youtube') {
            final vid = getVideoId(b['content']?.toString() ?? '');
            if (vid.isNotEmpty) {
              videoId = vid;
              break;
            }
          }
        }
      }
    }

    if (videoId.isNotEmpty) {
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final categories = CategoryMetadata.categories;
    final potato = context.watch<PotatoModeProvider>();
    final displayCategories = potato.lazyLoadingEnabled
        ? categories.take(potato.maxListItems).toList()
        : categories;

    final isMobile = AppTokens.isMobile(context);
    final crossAxisCount = isMobile ? 2 : (AppTokens.isTablet(context) ? 3 : 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedWrapper(
          addAnimation: true,
          delay: Duration.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المحاضرات والتصنيفات',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_isLoadingData)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.spacing12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppTokens.spacing12,
            mainAxisSpacing: AppTokens.spacing12,
            childAspectRatio: 0.78,
          ),
          itemCount: displayCategories.length,
          itemBuilder: (context, index) {
            final category = displayCategories[index];
            final lectures = _categoryLectures[category.id] ?? [];
            final completedCount = _categoryCompleted[category.id] ?? 0;
            final latestThumbnail = _getLatestThumbnail(lectures);

            return CategoryCard(
              category: category,
              latestThumbnailUrl: latestThumbnail,
              totalLectures: lectures.length,
              completedLectures: completedCount,
              scoreSum: 0,
              scoreAvg: 0,
              examCount: 0,
              onTap: () => context.go(
                AppRoutes.lectures,
                extra: {'initialTabIndex': index},
              ),
            );
          },
        ),
      ],
    );
  }
}
