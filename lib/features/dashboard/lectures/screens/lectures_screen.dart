import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/empty_state.dart';
import 'package:arabilogia/core/widgets/error_state.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:arabilogia/core/widgets/loading_skeleton.dart';
import 'package:arabilogia/core/widgets/responsive_app_bar_title.dart';
import 'package:arabilogia/core/widgets/skeletons.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/lectures/repositories/lecture_repository.dart';
import 'package:arabilogia/features/dashboard/lectures/widgets/lecture_card.dart';
import 'package:go_router/go_router.dart';

enum _LectureSort { order, latest, progress }

class LecturesScreen extends StatefulWidget {
  final int initialTabIndex;
  const LecturesScreen({super.key, this.initialTabIndex = 0});

  @override
  State<LecturesScreen> createState() => _LecturesScreenState();
}

class _LecturesScreenState extends State<LecturesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<CategoryMetadata> _subjects = CategoryMetadata.categories;

  final LectureRepository _lectureRepository = LectureRepository();
  final Map<int, List<Map<String, dynamic>>> _lecturesByTab = {};
  final Map<int, bool> _isLoadingByTab = {};
  final Map<int, String?> _errorByTab = {};

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _LectureSort _sort = _LectureSort.order;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _subjects.length,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(_handleTabChange);
    _fetchLectures(widget.initialTabIndex);
    _preloadAdjacent(widget.initialTabIndex);
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) setState(() => _prefs = prefs);
    });
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    final index = _tabController.index;
    _fetchLectures(index);
    _preloadAdjacent(index);
  }

  Future<void> _fetchLectures(int index) async {
    if (_lecturesByTab.containsKey(index) && _isLoadingByTab[index] == false) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoadingByTab[index] = true;
      _errorByTab[index] = null;
    });

    try {
      final subjectId = _subjects[index].id;
      final lectures = await _lectureRepository.getLecturesByCategory(
        subjectId,
      );

      if (mounted) {
        setState(() {
          _lecturesByTab[index] = lectures;
          _isLoadingByTab[index] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorByTab[index] = 'فشل تحميل المحاضرات';
          _isLoadingByTab[index] = false;
        });
      }
    }
  }

  void _preloadAdjacent(int currentIndex) {
    for (final offset in const [-1, 1]) {
      final idx = currentIndex + offset;
      if (idx >= 0 && idx < _subjects.length) {
        if (!_lecturesByTab.containsKey(idx) && _isLoadingByTab[idx] != true) {
          _fetchLectures(idx);
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTokens.isMobile(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: TestKeys.lecturesScreen,
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: const ResponsiveAppBarTitle('المحاضرات'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            dividerHeight: 0.0,
            indicatorColor: AppColors.blue,
            indicatorWeight: 3.5,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            labelStyle: TextStyle(
              fontSize: isMobile ? 14 : 18,
              fontWeight: FontWeight.w900,
            ),
            unselectedLabelColor:
                Theme.of(context).brightness == Brightness.dark
                ? AppColors.mutedDark
                : AppColors.textMuted,
            unselectedLabelStyle: TextStyle(
              fontSize: isMobile ? 13 : 16,
              fontWeight: FontWeight.w600,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppTokens.spacing4 : AppTokens.spacing16,
            ),
            tabs: _subjects
                .map(
                  (s) => Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile
                            ? AppTokens.spacing2
                            : AppTokens.spacing16,
                      ),
                      child: Text(s.name),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.spacing8,
                AppTokens.spacing8,
                AppTokens.spacing8,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن محاضرة...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                        border: OutlineInputBorder(
                          borderRadius: AppTokens.radiusMdAll,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.spacing4),
                  PopupMenuButton<_LectureSort>(
                    tooltip: 'ترتيب',
                    initialValue: _sort,
                    onSelected: (value) => setState(() => _sort = value),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _LectureSort.order,
                        child: Text('الترتيب'),
                      ),
                      PopupMenuItem(
                        value: _LectureSort.latest,
                        child: Text('الأحدث'),
                      ),
                      PopupMenuItem(
                        value: _LectureSort.progress,
                        child: Text('التقدم'),
                      ),
                    ],
                    icon: const Icon(Icons.sort),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List.generate(
                  _subjects.length,
                  (index) => _LectureTabContent(
                    key: ValueKey(index),
                    tabIndex: index,
                    lecturesByTab: _lecturesByTab,
                    isLoadingByTab: _isLoadingByTab,
                    errorByTab: _errorByTab,
                    subjects: _subjects,
                    prefs: _prefs,
                    searchQuery: _searchQuery,
                    sort: _sort,
                    onRetry: () {
                      setState(() => _lecturesByTab.remove(index));
                      _fetchLectures(index);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LectureTabContent extends StatefulWidget {
  final int tabIndex;
  final Map<int, List<Map<String, dynamic>>> lecturesByTab;
  final Map<int, bool> isLoadingByTab;
  final Map<int, String?> errorByTab;
  final List<CategoryMetadata> subjects;
  final SharedPreferences? prefs;
  final String searchQuery;
  final _LectureSort sort;
  final VoidCallback onRetry;

  const _LectureTabContent({
    required super.key,
    required this.tabIndex,
    required this.lecturesByTab,
    required this.isLoadingByTab,
    required this.errorByTab,
    required this.subjects,
    required this.prefs,
    required this.searchQuery,
    required this.sort,
    required this.onRetry,
  });

  @override
  State<_LectureTabContent> createState() => _LectureTabContentState();
}

class _LectureTabContentState extends State<_LectureTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _progressCount(Map<String, dynamic> lecture) {
    final id = lecture['id']?.toString() ?? '';
    if (id.isEmpty) return 0;
    return widget.prefs?.getStringList('lecture_progress_$id')?.length ?? 0;
  }

  List<Map<String, dynamic>> _visibleLectures(
    List<Map<String, dynamic>> lectures,
  ) {
    var list = List<Map<String, dynamic>>.from(lectures);
    final query = widget.searchQuery.trim();
    if (query.isNotEmpty) {
      list = list
          .where(
            (l) =>
                (l['title']?.toString() ?? '').contains(query) ||
                (l['description']?.toString() ?? '').contains(query),
          )
          .toList();
    }
    switch (widget.sort) {
      case _LectureSort.order:
        list.sort(
          (a, b) => ((a['sort_order'] ?? 0) as num).compareTo(
            (b['sort_order'] ?? 0) as num,
          ),
        );
      case _LectureSort.latest:
        list.sort(
          (a, b) => (b['created_at']?.toString() ?? '').compareTo(
            a['created_at']?.toString() ?? '',
          ),
        );
      case _LectureSort.progress:
        list.sort((a, b) => _progressCount(b).compareTo(_progressCount(a)));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tabIndex = widget.tabIndex;
    final isLoading = widget.isLoadingByTab[tabIndex] ?? true;
    final allLectures = widget.lecturesByTab[tabIndex] ?? [];
    final error = widget.errorByTab[tabIndex];

    if (isLoading && allLectures.isEmpty) {
      return const ListSkeleton(itemCount: 6, itemBuilder: SkeletonCard.new);
    }

    if (error != null) {
      return ErrorState(title: error, onRetry: widget.onRetry);
    }

    final lectures = _visibleLectures(allLectures);
    final currentSubject = widget.subjects[tabIndex];

    if (lectures.isEmpty) {
      if (widget.searchQuery.trim().isNotEmpty) {
        return const EmptyState(
          icon: Icons.search_off,
          title: 'لا توجد نتائج',
          message: 'جرب كلمات بحث مختلفة',
        );
      }
      return const EmptyState(
        icon: Icons.play_circle_outline,
        title: 'لا توجد محاضرات متاحة',
        message: 'سيتم إضافة محاضرات جديدة قريباً',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.spacing12,
        AppTokens.spacing12,
        AppTokens.spacing12,
        80,
      ),
      itemCount: lectures.length,
      itemBuilder: (context, index) {
        final lecture = lectures[index];
        return LectureCard(
          lecture: lecture,
          categoryColor: currentSubject.color,
          onTap: () {
            context.pushNamed(
              'lecture-detail',
              pathParameters: {'id': lecture['id']},
              extra: {
                'subjectId': currentSubject.id,
                'subjectName': currentSubject.name,
              },
            );
          },
        );
      },
    );
  }
}
