import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/widgets/native_ad_widget.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/core/services/potato_mode_service.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ExamsScreen extends StatefulWidget {
  final int initialTabIndex;
  const ExamsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<CategoryMetadata> _subjects = CategoryMetadata.categories;

  final ExamRepository _examRepository = ExamRepository();
  final Map<int, List<Map<String, dynamic>>> _examsByTab = {};
  final Map<int, bool> _isLoadingByTab = {};
  final Map<int, String?> _errorByTab = {};

  // Get ad frequency based on potato mode level
  int _getExamsPerAdInterval(PotatoLevel level) {
    switch (level) {
      case PotatoLevel.off:
        return 5; // Normal mode: show ad every 5 exams
      case PotatoLevel.sweet:
        return 3; // Sweet potato: show ad every 3 exams
      case PotatoLevel.tiny:
        return 2; // Tiny potato: show ad every 2 exams
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _subjects.length,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(_handleTabChange);
    _syncAndFetch();
  }

  Future<void> _syncAndFetch() async {
    await ScoreRepository().syncScoresWithSupabase();
    _fetchExams();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    final index = _tabController.index;
    if (_examsByTab.containsKey(index) && _isLoadingByTab[index] == false) {
      // Already loaded, we can skip or refresh in background
      // For now, let's refresh to ensure sync works
    }

    if (!mounted) return;
    setState(() {
      _isLoadingByTab[index] = true;
      _errorByTab[index] = null; // Clear previous error
    });

    try {
      final subjectId = _subjects[index].id;
      final exams = await _examRepository.getExamsBySubject(subjectId);

      if (mounted) {
        setState(() {
          _examsByTab[index] = exams;
          _isLoadingByTab[index] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorByTab[index] = 'فشل تحميل الامتحانات'; // Error message
          _isLoadingByTab[index] = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final potato = context.watch<PotatoModeProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الامتحانات'),
          bottom: potato.blurEffectsEnabled
              ? TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spacing16,
                  ),
                  tabs: _subjects
                      .map(
                        (s) => Tab(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.spacing4,
                            ),
                            child: Text(s.name),
                          ),
                        ),
                      )
                      .toList(),
                )
              : TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spacing16,
                  ),
                  tabs: _subjects
                      .map(
                        (s) => Tab(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.spacing4,
                            ),
                            child: Text(s.name),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: List.generate(
            _subjects.length,
            (index) => _buildExamList(context, index),
          ),
        ),
      ),
    );
  }

  Widget _buildExamList(BuildContext context, int tabIndex) {
    final isLoading = _isLoadingByTab[tabIndex] ?? true;
    final exams = _examsByTab[tabIndex] ?? [];
    final error = _errorByTab[tabIndex];

    if (isLoading && exams.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(error, style: TextStyle(color: AppColors.error)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _fetchExams,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: AppColors.mutedColor(context).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد امتحانات متاحة حالياً',
              style: TextStyle(color: AppColors.mutedColor(context)),
            ),
            Text(
              'ترقبونا قريباً!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedColor(context).withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    final potato = context.watch<PotatoModeProvider>();
    final displayExams = potato.lazyLoadingEnabled
        ? exams.take(potato.maxListItems).toList()
        : exams;

    // Get ad interval based on potato mode level
    final int examsPerAd = _getExamsPerAdInterval(potato.level);
    final int adInterval = examsPerAd + 1; // +1 because we insert after X exams

    // Calculate total item count including ads
    // Each ad is inserted after every X exams based on mode
    final int adCount = displayExams.length > examsPerAd 
        ? (displayExams.length - 1) ~/ examsPerAd 
        : 0;
    final int totalItems = displayExams.length + adCount;

    return ListView.builder(
      padding: const EdgeInsets.all(AppTokens.spacing8),
      itemCount: totalItems + 1, // +1 for bottom spacing
      itemBuilder: (context, index) {
        if (index == totalItems) {
          return const SizedBox(height: 80);
        }

        // Check if this position should be an ad
        // Ad appears after every X exams based on potato mode level
        // ad appears at: X+1, 2X+2, 3X+3... (0-based indices)
        if ((index + 1) % adInterval == 0 && index > 0 && displayExams.length > examsPerAd) {
          // This is an ad position
          return const SimpleNativeAdWidget();
        }

        // This is an exam - find the actual exam index
        // The actual exam index = position - number of ads before this position
        final int adsBeforeThis = displayExams.length > examsPerAd 
            ? (index ~/ adInterval) 
            : 0;
        final int actualExamIndex = index - adsBeforeThis;

        if (actualExamIndex >= displayExams.length) {
          return const SizedBox.shrink();
        }

        final exam = displayExams[actualExamIndex];
        return AnimatedWrapper(
          addAnimation: true,
          child: _buildExamCard(context, exam, tabIndex),
        );
      },
    );
  }

  Widget _buildExamCard(
    BuildContext context,
    Map<String, dynamic> exam,
    int tabIndex,
  ) {
    final isLocked = exam['locked'] == true;
    final isCompleted = exam['completed'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing8),
      child: Card(
        child: InkWell(
          onTap: isLocked
              ? null
              : () async {
                  final currentSubject = _subjects[tabIndex];
                  await context.pushNamed(
                    'exam-detail',
                    pathParameters: {'id': exam['id']},
                    extra: {
                      'subjectId': currentSubject.id,
                      'subjectName': currentSubject.name,
                    },
                  );
                  if (mounted) _fetchExams();
                },
          borderRadius: AppTokens.radius2xlAll,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spacing12),
            child: Row(
              children: [
                // Icon removed as requested, keeping space for alignment
                const SizedBox(width: AppTokens.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exam['title'] as String,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: isLocked
                                        ? AppColors.mutedColor(context)
                                        : null,
                                  ),
                            ),
                          ),
                          // Orange badge removed
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 14,
                            color: AppColors.mutedColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${exam['questions']} سؤال',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: AppColors.mutedColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${exam['duration']} دقيقة',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: AppTokens.radiusSmAll,
                    ),
                    child: Text(
                      '${exam['score']}%',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                else if (!isLocked)
                  Icon(
                    Icons.chevron_left,
                    color: AppColors.mutedColor(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
