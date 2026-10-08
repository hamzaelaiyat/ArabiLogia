import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/admin/services/docx_exam_parser.dart';

/// Content for the DOCX import preview. Designed to work both inside a
/// bottom sheet (mobile) and as a full page (desktop via ResponsiveOverlay).
class ImportDocxPreviewDialog extends StatelessWidget {
  final DocxParseResult result;

  const ImportDocxPreviewDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile =
        MediaQuery.of(context).size.width < AppTokens.breakpointTablet;

    if (isMobile) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(AppTokens.spacing12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.dashboardContentBgDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _buildContent(context, isDark),
        ),
      );
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: _buildContent(context, isDark),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.file_upload_outlined,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: AppTokens.spacing4),
            Text(
              'معاينة الاستيراد',
              style: TextStyle(
                fontSize: AppTokens.fontSizeXl,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.fgDark : AppColors.fgLight,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.of(context).pop(false),
              icon: Icon(
                Icons.close,
                color: isDark ? AppColors.mutedDark : AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spacing4),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spacing8,
            vertical: AppTokens.spacing4,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: AppTokens.radiusSmAll,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.quiz_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppTokens.spacing4),
              Text(
                '${result.questions.length} سؤال',
                style: TextStyle(
                  fontSize: AppTokens.fontSizeMd,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppTokens.spacing8),
              const Icon(
                Icons.article_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppTokens.spacing4),
              Text(
                '${result.passages.length} فقرة',
                style: TextStyle(
                  fontSize: AppTokens.fontSizeMd,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.spacing8),
        Expanded(
          child: ListView(
            children: [
              if (result.passages.isNotEmpty) ...[
                Text(
                  'الفقرات',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeMd,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.mutedDark : AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppTokens.spacing4),
                ...result.passages.map(
                  (passage) => _buildPassageCard(passage, isDark),
                ),
                const SizedBox(height: AppTokens.spacing8),
              ],
              if (result.questions.isNotEmpty) ...[
                Text(
                  'الأسئلة',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeMd,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.mutedDark : AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppTokens.spacing4),
                ...result.questions.asMap().entries.map(
                  (entry) =>
                      _buildQuestionCard(entry.key + 1, entry.value, isDark),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppTokens.spacing8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: isDark ? AppColors.mutedDark : AppColors.muted,
                ),
              ),
            ),
            const SizedBox(width: AppTokens.spacing4),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacing12,
                  vertical: AppTokens.spacing6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTokens.radiusMdAll,
                ),
              ),
              child: const Text('استيراد'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPassageCard(ParsedPassage passage, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing4),
      padding: const EdgeInsets.all(AppTokens.spacing6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: AppTokens.radiusSmAll,
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        passage.content,
        style: TextStyle(
          fontSize: AppTokens.fontSizeMd,
          color: isDark ? AppColors.fgDark : AppColors.fgLight,
          height: 1.6,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildQuestionCard(int number, ParsedQuestion question, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing4),
      padding: const EdgeInsets.all(AppTokens.spacing6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: AppTokens.radiusSmAll,
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: AppTokens.radiusSmAll,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontSize: AppTokens.fontSizeSm,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spacing4),
              Expanded(
                child: Text(
                  question.text,
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeMd,
                    color: isDark ? AppColors.fgDark : AppColors.fgLight,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (question.options.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spacing4),
            Wrap(
              spacing: AppTokens.spacing4,
              runSpacing: AppTokens.spacing2,
              children: question.options.asMap().entries.map((entry) {
                final labels = ['أ', 'ب', 'ج', 'د'];
                final idx = entry.key;
                final optText = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spacing4,
                    vertical: AppTokens.spacing2,
                  ),
                  decoration: BoxDecoration(
                    color: idx == 0
                        ? AppColors.success.withValues(alpha: 0.1)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03)),
                    borderRadius: AppTokens.radiusSmAll,
                    border: Border.all(
                      color: idx == 0
                          ? AppColors.success.withValues(alpha: 0.3)
                          : (isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.08)),
                    ),
                  ),
                  child: Text(
                    '${labels[idx]}) $optText',
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeSm,
                      color: isDark ? AppColors.fgDark : AppColors.fgLight,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
