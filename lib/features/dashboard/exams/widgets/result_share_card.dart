import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

/// A premium share card that looks and feels exactly like the ArabiLogia app.
///
/// Designed to be captured as a PNG image and shared. Uses the exact same
/// visual patterns as the app — the logo PNG alone, clouds background,
/// dark theme colors, glassmorphism, and orange primary.
class ResultShareCard extends StatelessWidget {
  final String studentName;
  final String examTitle;
  final int score;
  final int accuracy;
  final int speedBonus;
  final int correctCount;
  final int totalQuestions;
  final String grade;
  final bool isPassed;

  const ResultShareCard({
    super.key,
    required this.studentName,
    required this.examTitle,
    required this.score,
    required this.accuracy,
    required this.speedBonus,
    required this.correctCount,
    required this.totalQuestions,
    required this.grade,
    required this.isPassed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      height: 980,
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
      ),
      child: Stack(
        children: [
          // ── Full-bleed clouds background — same as auth screens ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/clouds-withlogo.png',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.55),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // ── Gradient overlay for depth ──
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 44),
            child: Column(
              children: [
                // ═══ Logo — same as login, register, sidebar (PNG alone, no text) ═══
                Image.asset(
                  'assets/images/logo-removedbg.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),

                const Spacer(flex: 2),

                // ═══ Achievement ═══
                const Text(
                  '🎉  لقد أتممت الاختبار بنجاح!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTokens.fontFamilyBody,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  examTitle,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTokens.fontFamilyBody,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 3),

                // ═══ Score circle with glow ═══
                _buildScoreCircle(),

                const Spacer(flex: 2),

                // ═══ Pass / Fail badge ═══
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: (isPassed ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    border: Border.all(
                      color: (isPassed ? AppColors.success : AppColors.error)
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    isPassed ? '✅ تم الاجتياز بنجاح' : '❌ لم يتم الاجتياز',
                    style: TextStyle(
                      color: isPassed ? AppColors.success : AppColors.error,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTokens.fontFamilyBody,
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ═══ Stats row — glass card ═══
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGlassDark,
                    borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('الدقة', '$accuracy%'),
                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.white12,
                      ),
                      _buildStat('النقاط', '+$speedBonus'),
                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.white12,
                      ),
                      _buildStat('الصحيحة', '$correctCount/$totalQuestions'),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ═══ Student info pill ═══
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTokens.fontFamilyBody,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        grade,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          fontFamily: AppTokens.fontFamilyBody,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ═══ Subtle footer ═══
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'عربيلوجيا — منصة اللغة العربية الأولى',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 13,
                        fontFamily: AppTokens.fontFamilyBody,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Score circle ───────────────────────

  Widget _buildScoreCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        // Progress ring
        SizedBox(
          width: 180,
          height: 180,
          child: CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 10,
            backgroundColor: Colors.white10,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeCap: StrokeCap.round,
          ),
        ),
        // Center content
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$score%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: AppTokens.fontFamilyBody,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'الدرجة النهائية',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontFamily: AppTokens.fontFamilyBody,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────── Stat item ───────────────────────

  Widget _buildStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: AppTokens.fontFamilyBody,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontFamily: AppTokens.fontFamilyBody,
          ),
        ),
      ],
    );
  }
}
