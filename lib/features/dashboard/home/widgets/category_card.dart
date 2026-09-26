import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';

class CategoryCard extends StatelessWidget {
  final CategoryMetadata category;
  final String? latestThumbnailUrl;
  final int totalLectures;
  final int completedLectures;
  final double scoreSum;
  final double scoreAvg;
  final int examCount;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    this.latestThumbnailUrl,
    required this.totalLectures,
    required this.completedLectures,
    required this.scoreSum,
    required this.scoreAvg,
    required this.examCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = _getRefinedCategoryColor(
      category.name,
      category.color,
      isDark,
    );

    final backlogCount = (totalLectures - completedLectures).clamp(
      0,
      totalLectures,
    );
    final String backlogText;
    if (totalLectures == 0) {
      backlogText = 'لا توجد محاضرات بعد';
    } else if (backlogCount > 0) {
      backlogText =
          'مراكم $backlogCount ${backlogCount == 1
              ? 'محاضرة'
              : backlogCount == 2
              ? 'محاضرتين'
              : 'محاضرات'}';
    } else {
      backlogText = 'مش مراكم';
    }

    final hasThumbnailImage =
        latestThumbnailUrl != null && latestThumbnailUrl!.isNotEmpty;

    return Semantics(
      label: '${category.name}، $totalLectures محاضرة، $backlogText',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDark
                    ? Colors.white12
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Upper Section: Thumbnail
                Expanded(
                  flex: 52,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasThumbnailImage)
                        latestThumbnailUrl!.startsWith('data:image')
                            ? Image.memory(
                                base64Decode(
                                  latestThumbnailUrl!.split(',').last,
                                ),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFallbackThumbnail(
                                      context,
                                      cardBgColor,
                                    ),
                              )
                            : Image.network(
                                latestThumbnailUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFallbackThumbnail(
                                      context,
                                      cardBgColor,
                                    ),
                              )
                      else
                        _buildFallbackThumbnail(context, cardBgColor),

                      // Gradient Overlay at bottom of thumbnail (only if an image is loaded)
                      if (hasThumbnailImage)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  cardBgColor.withValues(alpha: 0.7),
                                  cardBgColor,
                                ],
                                stops: const [0.4, 0.85, 1.0],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Lower Section: Subject Title & Real Backlog / Lecture counts
                Expanded(
                  flex: 48,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          backlogText,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalLectures محاضرة',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackThumbnail(BuildContext context, Color cardBgColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardBgColor.withValues(alpha: 0.9), cardBgColor],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(category.icon, size: 32, color: Colors.white),
        ),
      ),
    );
  }

  static Color _getRefinedCategoryColor(
    String name,
    Color fallbackColor,
    bool isDark,
  ) {
    switch (name) {
      case 'النحو':
        return isDark ? const Color(0xFF991B1B) : const Color(0xFFDC2626);
      case 'البلاغة':
        return isDark ? const Color(0xFF1D4ED8) : const Color(0xFF2563EB);
      case 'النصوص':
        return isDark ? const Color(0xFF047857) : const Color(0xFF059669);
      case 'القراءة':
        return isDark ? const Color(0xFF6D28D9) : const Color(0xFF7C3AED);
      case 'القصة':
        return isDark ? const Color(0xFFD97706) : const Color(0xFFEA580C);
      case 'الأدب':
        return isDark ? const Color(0xFF4D7C0F) : const Color(0xFF65A30D);
      case 'شامل':
        return isDark ? const Color(0xFFB45309) : const Color(0xFFD97706);
      case 'نصف شامل':
        return isDark ? const Color(0xFF0284C7) : const Color(0xFF03A9F4);
      default:
        return fallbackColor;
    }
  }
}
