import 'package:flutter/material.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/features/dashboard/leaderboard/repositories/leaderboard_repository.dart';
import 'package:arabilogia/core/routes/app_router.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:arabilogia/core/widgets/responsive_app_bar_title.dart';

import '../widgets/home_welcome_card.dart';
import '../widgets/quick_stats_row.dart';
import '../widgets/recent_activity_section.dart';
import '../widgets/exam_categories_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final ScoreRepository _scoreRepository = ScoreRepository();
  final LeaderboardRepository _leaderboardRepository = LeaderboardRepository();
  Map<String, dynamic>? _userStats;
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoadingActivities = true;

  @override
  void initState() {
    super.initState();
    _fetchRank();
    _fetchRecentActivity();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppRouter.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _fetchRank();
    _fetchRecentActivity();
  }

  Future<void> _fetchRank() async {
    try {
      final stats = await _leaderboardRepository.getUserStats();
      if (mounted) {
        setState(() {
          _userStats = stats;
        });
      }
    } catch (e) {
      // Rank fetch failed silently; stats stay null
    }
  }

  Future<void> _fetchRecentActivity() async {
    try {
      final activities = await _scoreRepository.getRecentActivity(limit: 3);
      if (mounted) {
        setState(() {
          _recentActivities = activities;
          _isLoadingActivities = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingActivities = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.state.user;
    final fullName = (user?.userMetadata?['full_name'] as String?) ?? 'طالبنا';
    final nameParts = fullName.split(' ');
    final displayName = nameParts.length > 1
        ? '${nameParts[0]} ${nameParts[1]}'
        : nameParts[0];
    final grade = user?.userMetadata?['grade'];
    final rank = _userStats?['rank'] ?? 0;
    final gradeText = _getGradeText(grade);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: TestKeys.homeScreen,
        extendBodyBehindAppBar: true,
        appBar: const GlassAppBar(
          title: ResponsiveAppBarTitle('الرئيسية'),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await _fetchRank();
            await _fetchRecentActivity();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top:
                  MediaQuery.paddingOf(context).top +
                  kToolbarHeight +
                  AppTokens.spacing16,
              left: AppTokens.isMobile(context)
                  ? AppTokens.dashboardPaddingMobile
                  : AppTokens.dashboardPadding,
              right: AppTokens.isMobile(context)
                  ? AppTokens.dashboardPaddingMobile
                  : AppTokens.dashboardPadding,
              bottom: AppTokens.isMobile(context)
                  ? AppTokens.dashboardPaddingMobile
                  : AppTokens.dashboardPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeWelcomeCard(
                  name: displayName,
                  gradeText: gradeText,
                  rank: rank,
                ),
                const SizedBox(height: AppTokens.spacing16),
                QuickStatsRow(
                  rank: rank,
                  exams: _userStats?['exams_completed'] ?? 0,
                  avg: _userStats?['avg_score'] ?? 0,
                ),
                const SizedBox(height: AppTokens.spacing16),
                RecentActivitySection(
                  activities: _recentActivities,
                  isLoading: _isLoadingActivities,
                ),
                const SizedBox(height: AppTokens.spacing16),
                const ExamCategoriesGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGradeText(dynamic grade) {
    if (grade == null) return 'رحلتك الدراسية';
    final g = grade is int ? grade : int.tryParse(grade.toString()) ?? 0;
    switch (g) {
      case 10:
        return 'الأولى باكالوريا';
      case 11:
        return 'الثانية ثانوي';
      case 12:
        return 'الثالثة ثانوي';
      default:
        return 'صفك الدراسي';
    }
  }
}
