import 'package:flutter/material.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/features/dashboard/lectures/repositories/lecture_activity_repository.dart';
import 'package:arabilogia/features/dashboard/leaderboard/repositories/leaderboard_repository.dart';
import 'package:arabilogia/core/routes/app_router.dart';
import 'package:arabilogia/core/widgets/error_state.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:arabilogia/core/widgets/responsive_app_bar_title.dart';
import 'package:arabilogia/core/widgets/user_avatar_action.dart';
import 'package:arabilogia/core/utils/grade_utils.dart';

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
  List<double> _scoresHistory = [];
  bool _isLoadingActivities = true;
  bool _hasActivityError = false;

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
      final activities = await _scoreRepository.getRecentActivity(limit: 10);
      final lectures = await LectureActivityRepository().getRecent();
      final merged = LectureActivityRepository.merge(lectures, activities);
      final localScoresMap = await _scoreRepository.getLocalScores();
      final List<double> extracted = [];

      for (final act in activities) {
        if (act['score'] != null) {
          final s = (act['score'] as num).toDouble();
          extracted.add(s);
        }
      }

      if (extracted.isEmpty && localScoresMap.isNotEmpty) {
        localScoresMap.forEach((_, data) {
          if (data is Map && data['score'] != null) {
            final s = (data['score'] as num).toDouble();
            extracted.add(s);
          }
        });
      }

      if (mounted) {
        setState(() {
          _recentActivities = merged.take(3).toList();
          _scoresHistory = extracted.reversed.toList();
          _isLoadingActivities = false;
          _hasActivityError = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load recent activity: $e');
      if (mounted) {
        setState(() {
          _isLoadingActivities = false;
          _hasActivityError = true;
        });
      }
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

    final isMobile = AppTokens.isMobile(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: TestKeys.homeScreen,
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: isMobile,
        appBar: isMobile
            ? const GlassAppBar(
                title: ResponsiveAppBarTitle('الرئيسية'),
                actions: [UserAvatarAction()],
              )
            : null,
        body: RefreshIndicator(
          onRefresh: () async {
            await _fetchRank();
            await _fetchRecentActivity();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: isMobile
                  ? MediaQuery.paddingOf(context).top +
                        kToolbarHeight +
                        AppTokens.spacing16
                  : AppTokens.spacing16,
              left: isMobile
                  ? AppTokens.dashboardPaddingMobile
                  : AppTokens.dashboardPadding,
              right: isMobile
                  ? AppTokens.dashboardPaddingMobile
                  : AppTokens.dashboardPadding,
              bottom: isMobile
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
                  scoresHistory: _scoresHistory,
                ),
                const SizedBox(height: AppTokens.spacing16),
                if (_hasActivityError)
                  ErrorState(
                    title: 'تعذر تحميل النشاط الأخير',
                    detail: 'تحقق من اتصالك بالإنترنت ثم أعد المحاولة',
                    onRetry: _fetchRecentActivity,
                  )
                else
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

  String _getGradeText(dynamic grade) =>
      getGradeText(grade, fallback: 'صفك الدراسي');
}
