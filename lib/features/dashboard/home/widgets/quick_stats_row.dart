import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'stat_card.dart';

class QuickStatsRow extends StatelessWidget {
  final int rank;
  final dynamic exams;
  final dynamic avg;

  const QuickStatsRow({
    super.key,
    required this.rank,
    required this.exams,
    required this.avg,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            value: '$exams',
            label: 'امتحانات مكتملة',
            icon: Icons.check_circle_outline,
            onTap: () => context.go(AppRoutes.exams),
          ),
        ),
        const SizedBox(width: AppTokens.spacing8),
        Expanded(
          child: StatCard(
            value: '$avg%',
            label: 'متوسط الدرجات',
            icon: Icons.trending_up,
            onTap: () => context.go(AppRoutes.leaderboard),
          ),
        ),
        const SizedBox(width: AppTokens.spacing8),
        Expanded(
          child: StatCard(
            value: rank > 0 ? '#$rank' : '-',
            label: 'ترتيبك',
            icon: Icons.leaderboard,
            onTap: () => context.go(AppRoutes.leaderboard),
          ),
        ),
      ],
    );
  }
}
