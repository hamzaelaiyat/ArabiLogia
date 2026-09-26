import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_text_styles.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/animated_wrapper.dart';
import '../utils/student_greeting_helper.dart';

class HomeWelcomeCard extends StatelessWidget {
  final String name;
  final String gradeText;
  final int rank;
  final int uncompletedLecturesCount;

  const HomeWelcomeCard({
    super.key,
    required this.name,
    required this.gradeText,
    required this.rank,
    this.uncompletedLecturesCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greeting = StudentGreetingHelper.getGreetingParts(name);
    final teacherSubtext = StudentGreetingHelper.getTeacherQuote(
      uncompletedLecturesCount: uncompletedLecturesCount,
    );
    final isDesktop = AppTokens.isDesktop(context);

    if (isDesktop) {
      // Computer / Desktop Layout: NO BORDERS, NO CONTAINERS, ON THE RIGHT, GREETING & NAME ON SAME LINE
      return Padding(
        padding: const EdgeInsets.only(
          right: AppTokens.spacing4,
          top: AppTokens.spacing4,
          bottom: AppTokens.spacing16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Right aligned in RTL!
          mainAxisSize: MainAxisSize.min,
          children: [
            // Greeting & Name on the exact SAME line without any container box!
            AnimatedWrapper(
              addAnimation: true,
              delay: Duration.zero,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${greeting.prefix} ',
                      style: AppTextStyles.displayMd.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.fgDark : AppColors.fgLight,
                      ),
                    ),
                    TextSpan(
                      text: greeting.name,
                      style: AppTextStyles.displayMd.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.fgDark : AppColors.fgLight,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(height: 4),

            // Dynamic Contextual Subtext right below the greeting on the right
            AnimatedWrapper(
              addAnimation: true,
              delay: const Duration(milliseconds: 60),
              child: Text(
                teacherSubtext,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.mutedDark : AppColors.textLight,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile Layout: Stacked & Start-Aligned (Prefix smaller above, Name larger below, Subtext below)
      return Semantics(
        label: '${greeting.prefix} ${greeting.name}',
        child: Padding(
          padding: const EdgeInsets.only(
            right: AppTokens.spacing4,
            top: AppTokens.spacing4,
            bottom: AppTokens.spacing16,
            left: AppTokens.spacing4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start, // Flush to the start/right edge!
            children: [
              // Greeting Prefix (smaller text above, e.g. "عامل ايه يا")
              AnimatedWrapper(
                addAnimation: true,
                delay: Duration.zero,
                child: Text(
                  greeting.prefix,
                  style: AppTextStyles.headingSm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.mutedDark : AppColors.textMuted,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              const SizedBox(height: 2),

              // Student Name (larger bold text below prefix)
              AnimatedWrapper(
                addAnimation: true,
                delay: const Duration(milliseconds: 40),
                child: Text(
                  greeting.name,
                  style: AppTextStyles.displayMd.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.fgDark : AppColors.fgLight,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              const SizedBox(height: 8),

              // Dynamic Contextual Subtext
              AnimatedWrapper(
                addAnimation: true,
                delay: const Duration(milliseconds: 80),
                child: Text(
                  teacherSubtext,
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.mutedDark : AppColors.textLight,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
