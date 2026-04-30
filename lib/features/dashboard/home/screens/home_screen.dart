import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:provider/provider.dart';

import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/core/routes/app_router.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final ScoreRepository _scoreRepository = ScoreRepository();
  Map<String, dynamic>? _userStats;
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoadingRank = true;
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
      final stats = await _scoreRepository.getUserStats();
      if (mounted) {
        setState(() {
          _userStats = stats;
          _isLoadingRank = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRank = false);
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
        extendBodyBehindAppBar: true,
        appBar: const GlassAppBar(
          title: Text(
            'عربيلوجيا',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
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
                _buildWelcomeCard(context, displayName, gradeText, rank),
                const SizedBox(height: AppTokens.spacing16),
                _buildQuickStats(
                  context,
                  rank: rank,
                  exams: _userStats?['exams_completed'] ?? 0,
                  avg: _userStats?['avg_score'] ?? 0,
                ),
                const SizedBox(height: AppTokens.spacing16),
                _buildRecentActivity(context),
                const SizedBox(height: AppTokens.spacing16),
                _buildExamCategories(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(
    BuildContext context,
    String name,
    String grade,
    int rank,
  ) {
    String subTitle;
    if (rank > 0) {
      final messages = _getMotivationalMessages(rank);
      subTitle = messages[DateTime.now().minute % messages.length];
    } else {
      subTitle = 'استعد للتفوق في $grade - امتحانات اللغة العربية';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.spacing16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryTo],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: AppTokens.radius2xlAll,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedWrapper(
                      addAnimation: true,
                      child: Text(
                        'مرحباً بك، $name',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.spacing4),
                    AnimatedWrapper(
                      addAnimation: true,
                      child: Text(
                        subTitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildQuickStats(
    BuildContext context, {
    int rank = 0,
    dynamic exams = 0,
    dynamic avg = 0,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            '$exams',
            'امتحانات مكتملة',
            Icons.check_circle_outline,
            onTap: () => context.go(AppRoutes.exams),
          ),
        ),
        const SizedBox(width: AppTokens.spacing8),
        Expanded(
          child: _buildStatCard(
            context,
            '$avg%',
            'متوسط الدرجات',
            Icons.trending_up,
            onTap: () => context.go(AppRoutes.leaderboard),
          ),
        ),
        const SizedBox(width: AppTokens.spacing8),
        Expanded(
          child: _buildStatCard(
            context,
            rank > 0 ? '#$rank' : '-',
            'ترتيبك',
            Icons.leaderboard,
            onTap: () => context.go(AppRoutes.leaderboard),
          ),
        ),
      ],
    );
  }

  List<String> _getMotivationalMessages(int rank) {
    if (rank <= 3) {
      return [
        "خارق! أنت من الصفوة",
        "بطل حقيقي! حافظ على القمة",
        "أداؤك مذهل، أنت قدوة للجميع",
      ];
    } else if (rank <= 10) {
      return [
        "أنت في المركز العاشر، حافظ على مكانك",
        "اقتربت من الثلاثة الأوائل! استمر",
        "أداء مذهل، المنافسة قوية وأنت أقوى",
        "أنت ضمن العشرة الذهبيين!",
        "مكانك في القمة محجوز، شد حيلك",
        "رائع! أنت من عمالقة هذا الأسبوع",
      ];
    } else if (rank <= 20) {
      return [
        "أنت ضمن أفضل 20، جود!",
        "باقي القليل للمنافسة في المركز العاشر",
        "رائع، استمر في الصعود",
        "خطوات واثقة نحو العشرة الأوائل",
        "أداؤك ثابت ومميز، لا تتوقف",
        "أنت تقترب من قائمة النخبة",
      ];
    } else if (rank <= 50) {
      return [
        "أداء جيد، لكن يمكنك الوصول للأفضل",
        "استعد للاختبار القادم بقوة",
        "المنافسة تشتد، كن مستعداً",
        "أنت في منطقة الأمان، انطلق للأمام",
        "لا يزال هناك الكثير لتقدمه، نحن نثق بك",
        "كل درجة ترفعك مراكز كثيرة، ركز!",
      ];
    } else {
      return [
        "بداية موفقة، استمر في التدرب",
        "كل اختبار يقربك من المتصدرين",
        "ثق في قدراتك! القادم أفضل",
        "رحلة الألف ميل تبدأ باختبار",
        "لا تستسلم، غداً ستكون من الثلاثة الأوائل",
        "التكرار يعلم الشطار، استمر في المحاولة",
      ];
    }
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppTokens.radiusLgAll,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTokens.radiusLgAll,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing8),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: AppTokens.iconSizeLg),
              const SizedBox(height: AppTokens.spacing4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'النشاط الأخير',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_recentActivities.isNotEmpty)
              TextButton(
                onPressed: () => context.go(AppRoutes.activityHistory),
                child: const Text(
                  'مشاهدة الكل',
                  style: TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.spacing8),
        if (_isLoadingActivities)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTokens.spacing16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_recentActivities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTokens.spacing16),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: AppTokens.radiusLgAll,
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 48,
                    color: AppColors.mutedColor(context).withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppTokens.spacing8),
                  Text(
                    'لا يوجد نشاط مؤخراً',
                    style: TextStyle(color: AppColors.mutedColor(context)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ابدأ اختباراً الآن لترى إنجازاتك',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedColor(
                        context,
                      ).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: _recentActivities.map((activity) {
              return _buildActivityTile(context, activity);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildActivityTile(
    BuildContext context,
    Map<String, dynamic> activity,
  ) {
    final category = CategoryMetadata.getByName(activity['subject']);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing8),
      padding: const EdgeInsets.all(AppTokens.spacing12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppTokens.radiusLgAll,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (category?.color ?? AppColors.primary).withValues(
                alpha: 0.1,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              category?.icon ?? Icons.quiz_outlined,
              color: category?.color ?? AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTokens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['subject'] ?? 'اختبار',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _getTimeAgo(activity['created_at']),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedColor(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppTokens.radiusFullAll,
            ),
            child: Text(
              '${(activity['score'] as num).toInt()}%',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';

      return 'منذ فترة';
    } catch (e) {
      return '';
    }
  }

  Widget _buildExamCategories(BuildContext context) {
    final categories = CategoryMetadata.categories;
    final potato = context.watch<PotatoModeProvider>();
    final displayCategories = potato.lazyLoadingEnabled
        ? categories.take(potato.maxListItems).toList()
        : categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedWrapper(
          addAnimation: true,
          child: Text(
            'الامتحانات',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppTokens.spacing8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: AppTokens.isMobile(context) ? 2 : 3,
            crossAxisSpacing: AppTokens.spacing8,
            mainAxisSpacing: AppTokens.spacing8,
            childAspectRatio: 1.2,
          ),
          itemCount: displayCategories.length,
          itemBuilder: (context, index) {
            final category = displayCategories[index];
            return Container(
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: AppTokens.radiusLgAll,
              ),
              child: InkWell(
                onTap: () => context.go(
                  AppRoutes.exams,
                  extra: {'initialTabIndex': index},
                ),
                borderRadius: AppTokens.radiusLgAll,
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.spacing8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
