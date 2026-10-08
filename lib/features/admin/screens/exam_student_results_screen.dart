import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/utils/grade_utils.dart';
import 'package:arabilogia/core/widgets/responsive_overlay.dart';
import 'package:arabilogia/features/admin/widgets/exam_results_detail_view.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';

/// Step 2 of the teacher drill-down: every student's result for one exam,
/// plus the students of the exam's grade who have not attempted it.
class ExamStudentResultsScreen extends StatefulWidget {
  final String examId;
  final String examTitle;
  final int grade;

  const ExamStudentResultsScreen({
    super.key,
    required this.examId,
    required this.examTitle,
    required this.grade,
  });

  @override
  State<ExamStudentResultsScreen> createState() =>
      _ExamStudentResultsScreenState();
}

class _ExamStudentResultsScreenState extends State<ExamStudentResultsScreen> {
  final ExamRepository _examRepository = ExamRepository();

  bool _isLoading = true;
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _nonParticipants = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final participants = await _examRepository.getExamParticipants(
      widget.examId,
    );
    final gradeProfiles = await _examRepository.getGradeProfiles(widget.grade);
    if (!mounted) return;

    final attemptedUserIds = participants
        .map((p) => p['user_id'])
        .whereType<String>()
        .toSet();

    setState(() {
      _participants = participants;
      _nonParticipants = gradeProfiles
          .where((p) => !attemptedUserIds.contains(p['id']))
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: TestKeys.examStudentResultsScreen,
        appBar: AppBar(
          title: Text(
            widget.examTitle,
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

    return Column(
      children: [
        _SummaryBar(participants: _participants),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ExamResultsDetailView(
              participants: _participants,
              nonParticipants: _nonParticipants,
              onParticipantTap: _showParticipantSheet,
            ),
          ),
        ),
      ],
    );
  }

  void _showParticipantSheet(Map<String, dynamic> result) {
    final profile = result['profile'] as Map<String, dynamic>?;
    final score = (result['score'] as num?)?.toDouble();
    final points = (result['points'] as num?)?.toInt();
    final createdAt = result['created_at'] as String?;

    final content = _ParticipantSheetContent(
      name: profile?['full_name'] ?? profile?['username'] ?? 'مستخدم مجهول',
      username: profile?['username'] as String? ?? '—',
      grade: getGradeText(profile?['grade']),
      score: score,
      points: points,
      submittedAt: createdAt == null
          ? null
          : intl.DateFormat(
              'dd/MM/yyyy HH:mm',
            ).format(DateTime.parse(createdAt).toLocal()),
    );

    ResponsiveOverlay.show(
      context: context,
      title: 'تفاصيل الطالب',
      mobileBuilder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusXl),
          ),
        ),
        child: SafeArea(child: content),
      ),
      child: content,
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final List<Map<String, dynamic>> participants;

  const _SummaryBar({required this.participants});

  @override
  Widget build(BuildContext context) {
    final scores = participants
        .map((p) => (p['score'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    final average = scores.isEmpty
        ? null
        : scores.reduce((a, b) => a + b) / scores.length;
    final passed = scores.where((s) => s >= 50).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.spacing12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer(context),
        borderRadius: AppTokens.radiusLgAll,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'عدد الطلاب',
              value: '${participants.length}',
              icon: Icons.groups_outlined,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              label: 'الناجحون',
              value: '$passed',
              icon: Icons.check_circle_outline,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              label: 'المتوسط',
              value: average == null ? '--' : '${average.toStringAsFixed(0)}%',
              icon: Icons.insights_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
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
            fontSize: AppTokens.fontSizeLg,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTokens.fontSizeXs,
            color: AppColors.mutedColor(context),
          ),
        ),
      ],
    );
  }
}

class _ParticipantSheetContent extends StatelessWidget {
  final String name;
  final String username;
  final String grade;
  final double? score;
  final int? points;
  final String? submittedAt;

  const _ParticipantSheetContent({
    required this.name,
    required this.username,
    required this.grade,
    required this.score,
    required this.points,
    required this.submittedAt,
  });

  @override
  Widget build(BuildContext context) {
    final passed = (score ?? -1) >= 50;
    return Padding(
      padding: const EdgeInsets.all(AppTokens.spacing16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: passed ? AppColors.success : AppColors.error,
                child: Text(
                  score == null ? '--' : score!.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppTokens.fontSizeLg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '@$username',
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
            ],
          ),
          const SizedBox(height: AppTokens.spacing16),
          _DetailRow(label: 'الصف', value: grade),
          _DetailRow(
            label: 'الحالة',
            value: passed ? 'ناجح' : 'راسب',
            valueColor: passed ? AppColors.success : AppColors.error,
          ),
          if (points != null)
            _DetailRow(label: 'النقاط المكتسبة', value: '$points'),
          if (submittedAt != null)
            _DetailRow(label: 'وقت التسليم', value: submittedAt!),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacing4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: AppColors.mutedColor(context))),
          const SizedBox(width: AppTokens.spacing8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
