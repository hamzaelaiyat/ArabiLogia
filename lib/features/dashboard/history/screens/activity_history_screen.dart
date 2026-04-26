import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
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
      final data = await _scoreRepository.getRecentActivity(limit: 50);
      if (mounted) {
        setState(() {
          _activities = data;
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
        appBar: AppBar(
          title: const Text('سجل النشاطات'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchHistory,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : displayActivities.isEmpty
            ? _buildEmptyState()
            : PotatoModeWrapper(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppTokens.spacing16),
                  itemCount: displayActivities.length,
                  itemBuilder: (context, index) =>
                      _buildActivityTile(context, displayActivities[index]),
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 64,
            color: AppColors.mutedColor(context).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد نشاط مسجل بعد',
            style: TextStyle(color: AppColors.mutedColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(
    BuildContext context,
    Map<String, dynamic> activity,
  ) {
    final category = CategoryMetadata.getByName(activity['subject']);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing12),
      padding: const EdgeInsets.all(AppTokens.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppTokens.radiusLgAll,
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (category?.color ?? AppColors.primary).withValues(
                alpha: 0.1,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              category?.icon ?? Icons.quiz_outlined,
              color: category?.color ?? AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTokens.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['subject'] ?? 'اختبار',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _getTimeAgo(activity['created_at']),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedColor(context),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getScoreColor(
                    activity['score'],
                  ).withValues(alpha: 0.1),
                  borderRadius: AppTokens.radiusFullAll,
                ),
                child: Text(
                  '${(activity['score'] as num).toInt()}%',
                  style: TextStyle(
                    color: _getScoreColor(activity['score']),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(dynamic score) {
    final s = (score as num).toDouble();
    if (s >= 80) return AppColors.success;
    if (s >= 50) return AppColors.warning;
    return AppColors.error;
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
}
