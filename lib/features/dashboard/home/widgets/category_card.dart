import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';

class CategoryCard extends StatelessWidget {
  final CategoryMetadata category;
  final String? latestThumbnailUrl;
  final int lectureCount;
  final double scoreSum;
  final double scoreAvg;
  final int examCount;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    this.latestThumbnailUrl,
    required this.lectureCount,
    required this.scoreSum,
    required this.scoreAvg,
    required this.examCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: category.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: category.color.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Upper Section: Latest Lecture Thumbnail (x in mockup)
              Expanded(
                flex: 52,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (latestThumbnailUrl != null &&
                        latestThumbnailUrl!.isNotEmpty)
                      latestThumbnailUrl!.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(latestThumbnailUrl!.split(',').last),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFallbackThumbnail(context),
                            )
                          : Image.network(
                              latestThumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFallbackThumbnail(context),
                            )
                    else
                      _buildFallbackThumbnail(context),

                    // Soft Gradient Overlay at bottom of thumbnail
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              category.color.withValues(alpha: 0.8),
                              category.color,
                            ],
                            stops: const [0.5, 0.85, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Play / Video Indicator Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Lower Section: Category Title & Stats Info
              Expanded(
                flex: 48,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category Title (e.g. "نحو")
                      Text(
                        category.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Info Details: Lecture Count & Score Metrics
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.video_library_outlined,
                                size: 13,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$lectureCount محاضرات',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.stars_outlined,
                                size: 13,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  examCount > 0
                                      ? 'المجموع: ${scoreSum.toStringAsFixed(0)} | المتوسط: ${scoreAvg.toStringAsFixed(0)}%'
                                      : 'لا تتوفر درجات بعد',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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

  Widget _buildFallbackThumbnail(BuildContext context) {
    return Container(
      color: Colors.black12,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 34,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 2),
            Text(
              'أحدث محاضرة',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
