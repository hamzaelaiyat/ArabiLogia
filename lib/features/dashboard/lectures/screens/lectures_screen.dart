import 'package:flutter/material.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:arabilogia/core/widgets/skeletons.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/lectures/repositories/lecture_repository.dart';
import 'package:arabilogia/features/dashboard/lectures/widgets/lecture_card.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void dispose() {
    _tabController.dispose();
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
    final lectures = _lecturesByTab[tabIndex] ?? [];
    final error = _errorByTab[tabIndex];

    if (isLoading && lectures.isEmpty) {
      return ListSkeleton(
        itemCount: 6,
        itemBuilder: () => const _LectureCardSkeleton(),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppTokens.spacing8),
            TextButton(
              onPressed: () {
                setState(() => _lecturesByTab.remove(tabIndex));
                _fetchLectures();
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (lectures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppTokens.spacing8),
            Text(
              'لا توجد محاضرات متاحة',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTokens.spacing8),
      itemCount: lectures.length + 1,
      itemBuilder: (context, index) {
        if (index == lectures.length) {
          return const SizedBox(height: 80);
        }

        final lecture = lectures[index];
        final currentSubject = _subjects[tabIndex];
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

class _LectureCardSkeleton extends StatelessWidget {
  const _LectureCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTokens.radiusSmAll,
                ),
              ),
              const SizedBox(width: AppTokens.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
