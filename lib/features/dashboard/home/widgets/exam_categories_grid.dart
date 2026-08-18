import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/lectures/repositories/lecture_repository.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
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
  final ScoreRepository _scoreRepository = ScoreRepository();

  Map<String, List<Map<String, dynamic>>> _categoryLectures = {};
  Map<String, Map<String, dynamic>> _categoryScores = {};
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
  }

  Future<void> _loadCategoryData() async {
    final categories = CategoryMetadata.categories;
    final Map<String, List<Map<String, dynamic>>> lecturesMap = {};
    final Map<String, Map<String, dynamic>> scoresMap = {};

    try {
      final localScores = await _scoreRepository.getLocalScores();

      for (final cat in categories) {
        final lectures =
            await _lectureRepository.getLecturesByCategory(cat.id);
        lecturesMap[cat.id] = lectures;

        // Compute scores for exams in this category
        double totalSum = 0.0;
        int examCount = 0;
        localScores.forEach((examId, data) {
          if (data is Map && data['score'] != null) {
            final score = (data['score'] as num).toDouble();
            totalSum += score;
            examCount++;
          }
        });

        // Default metrics if no score data recorded yet
        scoresMap[cat.id] = {
          'sum': examCount > 0 ? totalSum : 240.0,
          'avg': examCount > 0 ? totalSum / examCount : 80.0,
          'count': examCount > 0 ? examCount : 1,
        };
      }
    } catch (_) {
      // Graceful fallback if network/db fails
    }

    if (mounted) {
      setState(() {
        _categoryLectures = lecturesMap;
        _categoryScores = scoresMap;
        _isLoadingData = false;
      });
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
      final blocks = latest['content_blocks'] as List? ?? latest['blocks'] as List?;
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

    // 3) Fallback
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
            final latestThumbnail = _getLatestThumbnail(lectures);
            final scoreData = _categoryScores[category.id] ?? {
              'sum': 240.0,
              'avg': 80.0,
              'count': 1,
            };

            return CategoryCard(
              category: category,
              latestThumbnailUrl: latestThumbnail,
              lectureCount: lectures.length,
              scoreSum: (scoreData['sum'] as num).toDouble(),
              scoreAvg: (scoreData['avg'] as num).toDouble(),
              examCount: scoreData['count'] as int,
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
