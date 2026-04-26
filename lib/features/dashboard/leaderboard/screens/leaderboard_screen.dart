import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:provider/provider.dart';

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
    // Fetch will happen in didChangeDependencies once we have user grade
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

    final gradeName = _getGradeName(_selectedGrade);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const GlassAppBar(
          title: Text(
            'المتصدرون',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            SizedBox(
              height: MediaQuery.paddingOf(context).top + kToolbarHeight,
            ),
            _buildFilters(context),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredLeaders.isEmpty
                  ? _buildEmptyState(context)
                  : PotatoModeWrapper(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppTokens.spacing8),
                        itemCount: filteredLeaders.length,
                        itemBuilder: (context, index) =>
                            _buildLeaderItem(context, filteredLeaders[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGradeName(int grade) {
    switch (grade) {
      case 10:
        return 'الأولى باكالوريا';
      case 11:
        return 'الثانية ثانوي';
      case 12:
        return 'الثالثة ثانوي';
      default:
        return 'كل الصفوف';
    }
  }

  int _getGradeValueFromLabel(String label) {
    if (label.contains('الأول')) return 10;
    if (label.contains('الثاني')) return 11;
    if (label.contains('الثالث')) return 12;
    return 0;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 64,
            color: AppColors.mutedColor(context).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد متصدرين لهذا الصف حالياً',
            style: TextStyle(color: AppColors.mutedColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.spacing8),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildGradeFilterChip(context, 'صفي الدراسي', true),
                const SizedBox(width: 8),
                _buildGradeFilterChip(context, 'كل الصفوف', false),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodChip(context, 'كل الوقت', 'all'),
                const SizedBox(width: 8),
                _buildPeriodChip(context, 'هذا الأسبوع', 'week'),
                const SizedBox(width: 8),
                _buildPeriodChip(context, 'هذا الشهر', 'month'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeFilterChip(
    BuildContext context,
    String label,
    bool onlyMyGrade,
  ) {
    final isSelected = _showOnlyMyGrade == onlyMyGrade;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _showOnlyMyGrade = onlyMyGrade;
            _selectedGrade = onlyMyGrade ? _userGrade : 0;
          });
          _fetchLeaderboard();
        }
      },
      selectedColor: AppColors.chipSelectedColor(context),
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

  Widget _buildPeriodChip(BuildContext context, String label, String value) {
    final isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected && _selectedPeriod != value) {
          setState(() => _selectedPeriod = value);
          _fetchLeaderboard();
        }
      },
      selectedColor: AppColors.chipSelectedColor(context),
    );
  }

  Widget _buildLeaderItem(BuildContext context, Map<String, dynamic> leader) {
    final rank = leader['rank'] as int;
    final isTopThree = rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.rankColor(rank, context),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${leader['rank']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isTopThree
                          ? Colors.white
                          : AppColors.mutedColor(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spacing8),
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: leader['avatar_url'] != null
                    ? NetworkImage(leader['avatar_url'])
                    : null,
                child: leader['avatar_url'] == null
                    ? Center(
                        child: Text(
                          _getAvatar(leader['full_name'] ?? ''),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            height: 1.0,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppTokens.spacing8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leader['full_name'] ?? '',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      _getGradeName(
                        leader['grade'] is int
                            ? leader['grade']
                            : int.tryParse(leader['grade']?.toString() ?? '') ??
                                  0,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '${(leader['total_score'] as num).toInt()}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAvatar(String name) {
    if (name.trim().isEmpty) return 'ط';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      // Use first letter of first name and first letter of second name without space
      final first = parts[0].isNotEmpty ? parts[0].substring(0, 1) : '';
      final second = parts[1].isNotEmpty ? parts[1].substring(0, 1) : '';
      return '$first$second';
    }
    return name.trim().isNotEmpty ? name.trim().substring(0, 1) : 'ط';
  }
}
