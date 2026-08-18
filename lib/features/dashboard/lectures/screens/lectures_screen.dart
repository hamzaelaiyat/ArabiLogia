import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/empty_state.dart';
import 'package:arabilogia/core/widgets/error_state.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:arabilogia/core/widgets/loading_skeleton.dart';
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
    _fetchLectures();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) setState(() => _prefs = prefs);
    });
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _fetchLectures();
  }

  Future<void> _fetchLectures() async {
    final index = _tabController.index;
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
      final lectures = await _lectureRepository.getLecturesByCategory(subjectId);

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

  int _progressCount(Map<String, dynamic> lecture) {
    final id = lecture['id']?.toString() ?? '';
    if (id.isEmpty) return 0;
    return _prefs?.getStringList('lecture_progress_$id')?.length ?? 0;
  }

  List<Map<String, dynamic>> _visibleLectures(
    List<Map<String, dynamic>> lectures,
  ) {
    var list = List<Map<String, dynamic>>.from(lectures);
    final query = _searchQuery.trim();
    if (query.isNotEmpty) {
      list = list
          .where((l) =>
              (l['title']?.toString() ?? '').contains(query) ||
              (l['description']?.toString() ?? '').contains(query))
          .toList();
    }
    switch (_sort) {
      case _LectureSort.order:
        list.sort((a, b) => ((a['sort_order'] ?? 0) as num)
            .compareTo((b['sort_order'] ?? 0) as num));
      case _LectureSort.latest:
        list.sort((a, b) => (b['created_at']?.toString() ?? '')
            .compareTo(a['created_at']?.toString() ?? ''));
      case _LectureSort.progress:
        list.sort((a, b) => _progressCount(b).compareTo(_progressCount(a)));
    }
    return list;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: TestKeys.lecturesScreen,
        appBar: GlassAppBar(
          title: const Text('المحاضرات'),
          bottom: TabBar(
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
            (index) => _buildLectureList(context, index),
          ),
        ),
      ),
    );
  }

  Widget _buildLectureList(BuildContext context, int tabIndex) {
    final isLoading = _isLoadingByTab[tabIndex] ?? true;
    final allLectures = _lecturesByTab[tabIndex] ?? [];
    final error = _errorByTab[tabIndex];

    if (isLoading && allLectures.isEmpty) {
      return ListSkeleton(
        itemCount: 6,
        itemBuilder: () => const SkeletonCard(height: 72),
      );
    }

    if (error != null) {
      return ErrorState(
        title: error,
        onRetry: () {
          setState(() => _lecturesByTab.remove(tabIndex));
          _fetchLectures();
        },
      );
    }

    final lectures = _visibleLectures(allLectures);

    return Column(
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
                  onChanged: (value) => setState(() => _searchQuery = value),
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
        Expanded(child: _buildListContent(context, tabIndex, lectures)),
      ],
    );
  }

  Widget _buildListContent(
    BuildContext context,
    int tabIndex,
    List<Map<String, dynamic>> lectures,
  ) {
    if (lectures.isEmpty) {
      if (_searchQuery.trim().isNotEmpty) {
        return EmptyState(
          icon: Icons.search_off,
          title: 'لا توجد نتائج',
          message: 'جرب كلمات بحث مختلفة',
          action: TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            child: const Text('مسح البحث'),
          ),
        );
      }
      return const EmptyState(
        icon: Icons.play_circle_outline,
        title: 'لا توجد محاضرات متاحة',
        message: 'سيتم إضافة محاضرات جديدة قريباً',
      );
    }

    final currentSubject = _subjects[tabIndex];

    Widget buildCard(int index) {
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
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppTokens.breakpointTablet) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.spacing8,
              AppTokens.spacing8,
              AppTokens.spacing8,
              80,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 110,
              crossAxisSpacing: AppTokens.spacing8,
            ),
            itemCount: lectures.length,
            itemBuilder: (context, index) => buildCard(index),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.spacing8,
            AppTokens.spacing8,
            AppTokens.spacing8,
            80,
          ),
          itemCount: lectures.length,
          itemBuilder: (context, index) => buildCard(index),
        );
      },
    );
  }
}
