import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';
import 'package:arabilogia/features/dashboard/exams/services/exam_session_service.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exam_header.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exam_stats_row.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exam_instructions_section.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/exam_bottom_bar.dart';

class ExamDetailsScreen extends StatefulWidget {
  final String examId;
  final String subjectId;
  final String subjectName;

  const ExamDetailsScreen({
    super.key,
    required this.examId,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<ExamDetailsScreen> createState() => _ExamDetailsScreenState();
}

class _ExamDetailsScreenState extends State<ExamDetailsScreen> {
  final ExamRepository _repository = ExamRepository();
  final ExamSessionService _sessionService = ExamSessionService();
  Exam? _exam;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExamMetadata();
  }

  Future<void> _loadExamMetadata() async {
    final exam = await _repository.loadExamById(
      widget.subjectId,
      widget.examId,
    );
    if (mounted) {
      setState(() {
        _exam = exam;
        _isLoading = false;
      });
    }
  }

  Future<void> _startExam() async {
    final savedSession = await _sessionService.getSession();

    if (savedSession != null && savedSession.examId == widget.examId) {
      if (!context.mounted) return;

      final remainingSeconds = savedSession.getRemainingSeconds();
      final remainingTime = _sessionService.formatRemainingTime(
        remainingSeconds,
      );

      final category = CategoryMetadata.categories.firstWhere(
        (c) => c.id == widget.subjectId,
      );

      final shouldResume = await showDialog<bool>(
        context: context,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('امتحان غير مكتمل'),
            content: Text(
              'لديك امتحان لم تكمله. هل تريد المتابعة؟\nالوقت المتبقي: $remainingTime',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('بدء جديد'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  backgroundColor: category.color,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text('متابعة'),
              ),
            ],
          ),
        ),
      );

      if (shouldResume == true) {
        if (!context.mounted) return;
        context.pushNamed(
          'exam-interaction',
          pathParameters: {'id': widget.examId},
          extra: {
            'subjectId': widget.subjectId,
            'subjectName': widget.subjectName,
          },
        );
        return;
      } else {
        await _sessionService.clearSession();
      }
    }

    if (!context.mounted) return;
    context.pushNamed(
      'exam-interaction',
      pathParameters: {'id': widget.examId},
      extra: {
        'subjectId': widget.subjectId,
        'subjectName': widget.subjectName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_exam == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('عذراً، لم يتم العثور على تفاصيل الامتحان'),
        ),
      );
    }

    final category = CategoryMetadata.categories.firstWhere(
      (c) => c.id == widget.subjectId,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        color: category.color,
                      ),
                      child: Center(
                        child: Icon(
                          category.icon,
                          size: 80,
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(AppTokens.spacing16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      ExamHeader(
                        subjectName: widget.subjectName,
                        subjectId: widget.subjectId,
                        title: _exam!.title,
                      ),
                      const SizedBox(height: AppTokens.spacing24),
                      ExamStatsRow(
                        questionCount: _exam!.questions.length,
                        durationMinutes: _exam!.durationMinutes,
                        subjectId: widget.subjectId,
                      ),
                      const SizedBox(height: AppTokens.spacing24),
                      ExamInstructionsSection(
                        subjectName: _exam!.subject,
                        durationMinutes: _exam!.durationMinutes,
                        subjectId: widget.subjectId,
                      ),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ExamBottomBar(
                color: category.color,
                onPressed: _startExam,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
