import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/features/dashboard/leaderboard/repositories/leaderboard_repository.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:arabilogia/core/widgets/error_state.dart';
import 'package:arabilogia/core/widgets/responsive_app_bar_title.dart';
import 'package:arabilogia/core/widgets/skeletons.dart';
import 'package:provider/provider.dart';
import '../widgets/leaderboard_empty_state.dart';
import '../widgets/leaderboard_filters.dart';
import '../widgets/leaderboard_podium.dart';
import '../widgets/leaderboard_rank_card.dart';
import '../widgets/leaderboard_user_profile_sheet.dart';
import '../widgets/leaderboard_helpers.dart';
import 'package:arabilogia/core/models/grade_metadata.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardRepository _leaderboardRepository = LeaderboardRepository();
  int _userGrade = GradeMetadata.allGrades;
  int _selectedGrade = GradeMetadata.allGrades;
  String _selectedPeriod = 'all';
  bool _initialized = false;
  bool _isLoading = true;
  bool _showOnlyMyGrade = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _leaders = [];

  @override
  void initState() {
    super.initState();
  }

  void _showUserProfile(Map<String, dynamic> userData) {
    LeaderboardUserProfileSheet.show(context: context, userData: userData);
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final data = await _leaderboardRepository.getLeaderboard(
        grade: _selectedGrade,
        period: _selectedPeriod,
      );
      if (mounted) {
        setState(() {
          _leaders = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load leaderboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = context.read<AuthProvider>().state.user;
      final grade = user?.userMetadata?['grade'];
      if (grade != null) {
        _userGrade = grade is int
            ? grade
            : int.tryParse(grade.toString()) ?? GradeMetadata.allGrades;
        _selectedGrade = _userGrade;
      }
      _initialized = true;
      _fetchLeaderboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final potato = context.watch<PotatoModeProvider>();
    final filteredLeaders = potato.lazyLoadingEnabled
        ? _leaders.take(potato.maxListItems).toList()
        : _leaders;

    final topThree = filteredLeaders
        .where((e) => (e['rank'] as int? ?? 99) <= 3)
        .toList();
    final remainingLeaders = filteredLeaders
        .where((e) => (e['rank'] as int? ?? 99) > 3)
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const GlassAppBar(title: ResponsiveAppBarTitle('المتصدرين')),
        body: Column(
          children: [
            // Top Row: Filters (صفي الدراسي / كل الصفوف)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacing16,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: LeaderboardFilters(
                  userGrade: _userGrade,
                  showOnlyMyGrade: _showOnlyMyGrade,
                  selectedPeriod: _selectedPeriod,
                  onGradeChanged: (onlyMyGrade) {
                    setState(() {
                      _showOnlyMyGrade = onlyMyGrade;
                      _selectedGrade = onlyMyGrade
                          ? _userGrade
                          : GradeMetadata.allGrades;
                    });
                    _fetchLeaderboard();
                  },
                  onPeriodChanged: (period) {
                    setState(() => _selectedPeriod = period);
                    _fetchLeaderboard();
                  },
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? ListSkeleton(
                      itemCount: 8,
                      itemBuilder: () => const LeaderboardRowSkeleton(),
                    )
                  : _hasError
                  ? ErrorState(
                      title: 'تعذر تحميل المتصدرين',
                      detail: 'تحقق من اتصالك بالإنترنت ثم أعد المحاولة',
                      onRetry: _fetchLeaderboard,
                    )
                  : filteredLeaders.isEmpty
                  ? const LeaderboardEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spacing16,
                        vertical: AppTokens.spacing8,
                      ),
                      child: Column(
                        children: [
                          // Top 3 Podium Pedestals (#2, #1, #3)
                          if (topThree.isNotEmpty)
                            LeaderboardPodiumWidget(
                              topThree: topThree,
                              currentUserId: context
                                  .read<AuthProvider>()
                                  .state
                                  .user
                                  ?.id,
                              onUserTap: _showUserProfile,
                            ),

                          const SizedBox(height: 12),

                          // Ranks #4, #5, #6... List/Grid Layout
                          if (remainingLeaders.isNotEmpty)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isDesktop =
                                    constraints.maxWidth >=
                                    AppTokens.breakpointTablet;
                                if (isDesktop) {
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisExtent: 82,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 8,
                                        ),
                                    itemCount: remainingLeaders.length,
                                    itemBuilder: (context, index) {
                                      final leader = remainingLeaders[index];
                                      return _buildRankCard(leader);
                                    },
                                  );
                                }
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: remainingLeaders.length,
                                  itemBuilder: (context, index) {
                                    final leader = remainingLeaders[index];
                                    return _buildRankCard(leader);
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankCard(Map<String, dynamic> leader) {
    final rank = leader['rank'] as int? ?? 0;
    final currentUserId = context.read<AuthProvider>().state.user?.id;
    final isMe = currentUserId != null && leader['user_id'] == currentUserId;
    final gradeName = getGradeName(
      leader['grade'] is int
          ? leader['grade']
          : int.tryParse(leader['grade']?.toString() ?? '') ?? 0,
    );
    final avatarLetters = getAvatar(leader['full_name'] ?? '');

    return LeaderboardRankCard(
      leader: leader,
      isMe: isMe,
      rank: rank,
      isTopThree: false,
      gradeName: gradeName,
      avatarLetters: avatarLetters,
      onTap: () => _showUserProfile(leader),
    );
  }
}
