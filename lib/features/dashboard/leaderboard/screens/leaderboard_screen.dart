import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:arabilogia/core/widgets/responsive_app_bar_title.dart';
import 'package:provider/provider.dart';
import '../widgets/leaderboard_empty_state.dart';
import '../widgets/leaderboard_filters.dart';
import '../widgets/leaderboard_rank_card.dart';
import '../widgets/leaderboard_helpers.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ScoreRepository _scoreRepository = ScoreRepository();
  int _userGrade = 0;
  int _selectedGrade = 0;
  String _selectedPeriod = 'all';
  bool _initialized = false;
  bool _isLoading = true;
  bool _showOnlyMyGrade = true;
  List<Map<String, dynamic>> _leaders = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await _scoreRepository.getLeaderboard(
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = context.read<AuthProvider>().state.user;
      final grade = user?.userMetadata?['grade'];
      if (grade != null) {
        _userGrade = grade is int ? grade : int.tryParse(grade.toString()) ?? 0;
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const GlassAppBar(
          title: ResponsiveAppBarTitle('المتصدرون'),
        ),
        body: Column(
          children: [
            SizedBox(
              height: MediaQuery.paddingOf(context).top + kToolbarHeight,
            ),
            LeaderboardFilters(
              userGrade: _userGrade,
              showOnlyMyGrade: _showOnlyMyGrade,
              selectedPeriod: _selectedPeriod,
              onGradeChanged: (onlyMyGrade) {
                setState(() {
                  _showOnlyMyGrade = onlyMyGrade;
                  _selectedGrade = onlyMyGrade ? _userGrade : 0;
                });
                _fetchLeaderboard();
              },
              onPeriodChanged: (period) {
                setState(() => _selectedPeriod = period);
                _fetchLeaderboard();
              },
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredLeaders.isEmpty
                  ? const LeaderboardEmptyState()
                  : PotatoModeWrapper(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppTokens.spacing8),
                        itemCount: filteredLeaders.length,
                        itemBuilder: (context, index) {
                          final leader = filteredLeaders[index];
                          final rank = leader['rank'] as int;
                          final currentUserId =
                              context.read<AuthProvider>().state.user?.id;
                          final isMe = currentUserId != null &&
                              leader['user_id'] == currentUserId;
                          final gradeName = getGradeName(
                            leader['grade'] is int
                                ? leader['grade']
                                : int.tryParse(
                                        leader['grade']?.toString() ?? '') ??
                                    0,
                          );
                          final avatarLetters =
                              getAvatar(leader['full_name'] ?? '');
                          return LeaderboardRankCard(
                            leader: leader,
                            isMe: isMe,
                            rank: rank,
                            isTopThree: rank <= 3,
                            gradeName: gradeName,
                            avatarLetters: avatarLetters,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value) {
    final isSelected =
        _selectedGrade.toString() == value ||
        (value == 'all' && _selectedGrade == 0);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedGrade = value == 'all' ? 0 : int.parse(value);
        });
        _fetchLeaderboard();
      },
      selectedColor: AppColors.chipSelectedColor(context),
    );
  }
}
