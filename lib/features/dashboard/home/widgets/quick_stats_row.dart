import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'stat_card.dart';
import 'student_performance_chart_card.dart';

class QuickStatsRow extends StatelessWidget {
  final int rank;
  final dynamic exams;
  final dynamic avg;
  final List<double>? scoresHistory;

  const QuickStatsRow({
    super.key,
    required this.rank,
    required this.exams,
    required this.avg,
    this.scoresHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppTokens.isDesktop(context);
    final examsCount = (exams is num)
        ? exams.toInt()
        : (int.tryParse('$exams') ?? 0);
    final avgScore = (avg is num)
        ? avg.toDouble()
        : (double.tryParse('$avg') ?? 0.0);
    final rankVal = rank > 0 ? '$rank' : '-';
    final cardSpacing = isDesktop ? AppTokens.spacing12 : 8.0;

    return SizedBox(
      height: isDesktop ? 150 : 118,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stat 1: Solved exams
          Expanded(
            child: StatCard(
              topTitle: 'حليت',
              value: '$examsCount',
              bottomSubTitle: 'امتحان',
              onTap: () => context.go(AppRoutes.exams),
            ),
          ),
          SizedBox(width: cardSpacing),

          // Stat 2: Avg score
          Expanded(
            child: StatCard(
              topTitle: 'متوسط',
              value: '${avgScore.toStringAsFixed(0)}%',
              bottomSubTitle: 'درجات',
              onTap: () => context.go(AppRoutes.leaderboard),
            ),
          ),
          SizedBox(width: cardSpacing),

          // Stat 3: Leaderboard rank
          Expanded(
            child: StatCard(
              topTitle: 'ترتيبك',
              value: rankVal,
              bottomSubTitle: 'عالدفعة',
              onTap: () => context.go(AppRoutes.leaderboard),
            ),
          ),

          // Stat 4: Desktop performance chart (Computer version ONLY)
          if (isDesktop) ...[
            SizedBox(width: cardSpacing),
            Expanded(
              child: StudentPerformanceChartCard(
                avgScore: avgScore > 0 ? avgScore : 91.0,
                scoresHistory: scoresHistory,
                onTap: () => context.go(AppRoutes.leaderboard),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
