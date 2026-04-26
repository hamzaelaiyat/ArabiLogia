import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'dart:ui' as ui;

class ResultShareCard extends StatelessWidget {
  final String studentName;
  final String examTitle;
  final String subject;
  final int score;
  final int accuracy;
  final int speedBonus;
  final String grade;

  const ResultShareCard({
    super.key,
    required this.studentName,
    required this.examTitle,
    required this.subject,
    required this.score,
    required this.accuracy,
    required this.speedBonus,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    // We use a fixed size for consistent capture quality
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF191B1D),
        borderRadius: AppTokens.radiusLgAll,
      ),
      child: Stack(
        children: [
          // Background Pattern/Gradient
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/clouds-withlogo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Glass Content
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Branding
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo-smallerfortitle.png',
                      height: 40,
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'عربيلوجيا',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ReadexPro',
                          ),
                        ),
                        Text(
                          'مجموعة وليد قطب',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Achievement Title
                const Text(
                  'لقد أتممت الاختبار بنجاح!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ReadexPro',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  examTitle,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ReadexPro',
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Score Circle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ReadexPro',
                          ),
                        ),
                        const Text(
                          'الدرجة النهائية',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Stats Breakdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: AppTokens.radiusMdAll,
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('الدقة', '$accuracy%'),
                      Container(width: 1, height: 20, color: Colors.white24),
                      _buildMiniStat('مكافأة السرعة', '+$speedBonus'),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Student Info
                Text(
                  studentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'ReadexPro',
                  ),
                ),
                Text(
                  grade,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontFamily: 'Rubik',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'ReadexPro',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontFamily: 'Rubik',
          ),
        ),
      ],
    );
  }
}
