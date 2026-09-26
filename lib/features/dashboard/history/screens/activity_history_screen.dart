import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/empty_state.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/core/widgets/potato_mode_wrapper.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/features/dashboard/lectures/repositories/lecture_activity_repository.dart';
import 'package:arabilogia/features/dashboard/home/widgets/activity_tile.dart';
import 'package:provider/provider.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  final ScoreRepository _scoreRepository = ScoreRepository();
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final exams = await _scoreRepository.getRecentActivity(limit: 50);
      final lectures = await LectureActivityRepository().getRecent();
      final merged = LectureActivityRepository.merge(lectures, exams);
      if (mounted) {
        setState(() {
          _activities = merged;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final potato = context.watch<PotatoModeProvider>();
    final displayActivities = potato.lazyLoadingEnabled
        ? _activities.take(potato.maxListItems).toList()
        : _activities;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          title: const Text('سجل النشاطات'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
              onPressed: _fetchHistory,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : displayActivities.isEmpty
            ? const EmptyState(
                icon: Icons.history_outlined,
                title: 'لا يوجد نشاط مسجل بعد',
                message: 'شاهد محاضرة أو اختباراً لترى نشاطك هنا',
              )
            : PotatoModeWrapper(
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    top:
                        MediaQuery.paddingOf(context).top +
                        kToolbarHeight +
                        AppTokens.spacing16,
                    left: AppTokens.spacing12,
                    right: AppTokens.spacing12,
                    bottom: AppTokens.spacing24,
                  ),
                  itemCount: displayActivities.length,
                  itemBuilder: (context, index) =>
                      ActivityTile(activity: displayActivities[index]),
                ),
              ),
      ),
    );
  }
}
