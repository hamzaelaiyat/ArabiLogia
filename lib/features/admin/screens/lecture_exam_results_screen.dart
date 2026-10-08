import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';
import 'package:arabilogia/features/dashboard/lectures/models/lecture.dart';
import 'package:arabilogia/core/models/grade_metadata.dart';

/// Step 1 of the teacher drill-down: every exam attached to one lecture, with
/// how many students sat it and how they scored. Tapping an exam opens
/// [ExamStudentResultsScreen] for the per-student breakdown.
class LectureExamResultsScreen extends StatefulWidget {
  final Lecture lecture;

  const LectureExamResultsScreen({super.key, required this.lecture});

  @override
  State<LectureExamResultsScreen> createState() =>
      _LectureExamResultsScreenState();
}

class _LectureExamResultsScreenState extends State<LectureExamResultsScreen> {
  final ExamRepository _examRepository = ExamRepository();

  bool _isLoading = true;
  List<Map<String, dynamic>> _exams = [];
  Map<String, ExamResultAggregate> _aggregates = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final examIds = widget.lecture.examIds;
    if (examIds.isEmpty) {
      if (mounted) {
        setState(() {
          _exams = [];
          _aggregates = const {};
          _isLoading = false;
        });
      }
      return;
    }

    final exams = await _examRepository.getExamSummaries(examIds);
    final aggregates = await _examRepository.getAggregatesForExams(examIds);
    if (!mounted) return;
    setState(() {
      _exams = exams;
      _aggregates = aggregates;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: TestKeys.lectureResultsScreen,
        appBar: AppBar(
          title: Text(
            widget.lecture.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
        ),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_exams.isEmpty) {
      return const _EmptyState(
        icon: Icons.assignment_outlined,
        title: 'لا توجد امتحانات في هذه المحاضرة',
        subtitle:
            'اربط الامتحانات بالمحاضرة من محرر المحاضرة لتظهر نتائجها هنا.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppTokens.dashboardPaddingMobile),
        itemCount: _exams.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spacing8),
        itemBuilder: (context, index) {
          if (index == 0) return _buildSummaryHeader();
          final exam = _exams[index - 1];
          return _ExamStatCard(
            exam: exam,
            aggregate: _aggregates[exam['id']] ?? ExamResultAggregate.empty,
            onTap: () => context.push(
              AppRoutes.examStudentResults,
              extra: {
                'examId': exam['id'],
                'examTitle': exam['title'] ?? 'امتحان',
                'grade': exam['grade'] as int? ?? GradeMetadata.allGrades,
                'lectureTitle': widget.lecture.title,
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final totalParticipants = _aggregates.values.fold<int>(
      0,
      (sum, agg) => sum + agg.participants,
    );
    final averages = _aggregates.values
        .where((agg) => agg.averageScore != null)
        .map((agg) => agg.averageScore!)
        .toList();
    final overallAverage = averages.isEmpty
        ? null
        : averages.reduce((a, b) => a + b) / averages.length;

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacing12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer(context),
        borderRadius: AppTokens.radiusLgAll,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
              label: 'عدد الامتحانات',
              value: '${_exams.length}',
              icon: Icons.fact_check_outlined,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
          Expanded(
            child: _SummaryStat(
              label: 'إجمالي المحاولات',
              value: '$totalParticipants',
              icon: Icons.groups_outlined,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
          Expanded(
            child: _SummaryStat(
              label: 'المتوسط العام',
              value: overallAverage == null
                  ? '--'
                  : '${overallAverage.toStringAsFixed(0)}%',
              icon: Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: AppTokens.spacing2),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppTokens.fontSizeXl,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontSize: AppTokens.fontSizeXs,
            color: AppColors.mutedColor(context),
          ),
        ),
      ],
    );
  }
}

class _ExamStatCard extends StatelessWidget {
  final Map<String, dynamic> exam;
  final ExamResultAggregate aggregate;
  final VoidCallback onTap;

  const _ExamStatCard({
    required this.exam,
    required this.aggregate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final average = aggregate.averageScore;
    final hasAttempts = aggregate.participants > 0;

    return Card(
      elevation: AppTokens.elevationNone,
      shape: RoundedRectangleBorder(borderRadius: AppTokens.radiusMdAll),
      color: AppColors.surface(context),
      child: InkWell(
        borderRadius: AppTokens.radiusMdAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTokens.spacing10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTokens.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam['title'] ?? 'امتحان',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: AppTokens.fontSizeMd,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spacing2),
                    Text(
                      hasAttempts
                          ? '${aggregate.participants} طالب • متوسط ${average!.toStringAsFixed(0)}%'
                          : 'لم يؤدِّ أي طالب هذا الامتحان بعد',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTokens.fontSizeSm,
                        color: AppColors.mutedColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasAttempts) ...[
                const SizedBox(width: AppTokens.spacing8),
                _ScoreBadge(score: average!),
              ],
              Icon(
                Icons.chevron_left,
                size: 20,
                color: AppColors.mutedColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 50 ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing8,
        vertical: AppTokens.spacing2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppTokens.radiusFullAll,
      ),
      child: Text(
        '${score.toStringAsFixed(0)}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: AppTokens.fontSizeSm,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.mutedColor(context)),
            const SizedBox(height: AppTokens.spacing12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeLg,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.spacing8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTokens.fontSizeMd,
                color: AppColors.mutedColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
