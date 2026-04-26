import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';
import 'dart:ui';

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
  Exam? _exam;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExamMetadata();
  }

  Future<void> _loadExamMetadata() async {
    final exam = await _repository.loadExamById(widget.subjectId, widget.examId);
    if (mounted) {
      setState(() {
        _exam = exam;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_exam == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('عذراً، لم يتم العثور على تفاصيل الامتحان')),
      );
    }

    final category = CategoryMetadata.categories.firstWhere((c) => c.id == widget.subjectId);

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
                        gradient: LinearGradient(
                          colors: [
                            category.color,
                            category.color.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          category.icon,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(AppTokens.spacing16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(context),
                      const SizedBox(height: AppTokens.spacing24),
                      _buildStats(context),
                      const SizedBox(height: AppTokens.spacing24),
                      _buildSectionTitle(context, 'الوصف'),
                      const SizedBox(height: AppTokens.spacing8),
                      Text(
                        'يتناول هذا الاختبار مهارات ${_exam!.subject} المقررة. تأكد من مراجعة الدروس جيداً قبل البدء.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedColor(context),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppTokens.spacing24),
                      _buildSectionTitle(context, 'تعليمات هامة'),
                      const SizedBox(height: AppTokens.spacing12),
                      _buildInstructionItem(context, 'تأكد من استقرار اتصال الإنترنت.'),
                      _buildInstructionItem(context, 'لديك ${_exam!.durationMinutes} دقيقة فقط لإنهاء الاختبار.'),
                      _buildInstructionItem(context, 'بمجرد البدء، لا يمكنك إيقاف المؤقت أو الخروج من الامتحان.'),
                      _buildInstructionItem(context, 'سيتم احتساب الدرجة من المحاولة الأولى فقط (للمتصدرين).'),
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
              child: _buildBottomBar(context, category),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: CategoryMetadata.categories.firstWhere((c) => c.id == widget.subjectId).color.withValues(alpha: 0.1),
            borderRadius: AppTokens.radiusFullAll,
          ),
          child: Text(
            widget.subjectName,
            style: TextStyle(
              color: CategoryMetadata.categories.firstWhere((c) => c.id == widget.subjectId).color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: AppTokens.spacing12),
        Text(
          _exam!.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    return Row(
      children: [
        _buildStatItem(
          context,
          '${_exam!.questions.length}',
          'سؤال',
          Icons.help_outline,
        ),
        const SizedBox(width: AppTokens.spacing16),
        _buildStatItem(
          context,
          '${_exam!.durationMinutes}',
          'دقيقة',
          Icons.timer_outlined,
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, IconData icon) {
    final color = CategoryMetadata.categories.firstWhere((c) => c.id == widget.subjectId).color;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: AppTokens.radiusLgAll,
          border: Border.all(
            color: color.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppTokens.spacing12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInstructionItem(BuildContext context, String text) {
    final color = CategoryMetadata.categories.firstWhere((c) => c.id == widget.subjectId).color;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppTokens.spacing8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CategoryMetadata category) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTokens.spacing16,
        AppTokens.spacing16,
        AppTokens.spacing16,
        MediaQuery.of(context).padding.bottom + AppTokens.spacing16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ElevatedButton(
            onPressed: () => context.pushNamed(
              'exam-interaction',
              pathParameters: {'id': widget.examId},
              extra: {
                'subjectId': widget.subjectId,
                'subjectName': widget.subjectName,
              },
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: category.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'ابدأ الاختبار الآن',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
