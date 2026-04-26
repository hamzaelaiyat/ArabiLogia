import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/result_share_card.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';

class ExamResultScreen extends StatefulWidget {
  final Exam exam;
  final Map<int, String?> userAnswers;
  final int score;
  final int accuracy;
  final int speedBonus;
  final int correctCount;
  final bool isFirstAttempt;

  const ExamResultScreen({
    super.key,
    required this.exam,
    required this.userAnswers,
    required this.score,
    required this.accuracy,
    required this.speedBonus,
    required this.correctCount,
    this.isFirstAttempt = true,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  final GlobalKey _shareKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareResult() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      RenderRepaintBoundary? boundary = 
          _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/score_share.png').create();
      await imagePath.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'لقد حصلت على ${widget.score}% في اختبار ${widget.exam.title} على تطبيق عربيلوجيا! 🎉',
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPassed = widget.score >= 50;
    final authProvider = context.read<AuthProvider>();
    final userMetadata = authProvider.state.user?.userMetadata;
    final studentName = userMetadata?['full_name'] ?? userMetadata?['username'] ?? 'طالب عربيلوجيا';
    final gradeRaw = userMetadata?['grade'];
    final gradeText = _getGradeText(gradeRaw);
    
    final wrongAnswerIndices = [];
    for (int i = 0; i < widget.exam.questions.length; i++) {
      final question = widget.exam.questions[i];
      final selectedId = widget.userAnswers[i];
      final correctId = question.options.firstWhere((o) => o.isCorrect).id;
      if (selectedId != correctId) {
        wrongAnswerIndices.add(i);
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          title: const Text('نتيجة الاختبار'),
          automaticallyImplyLeading: false,
          actions: [
            if (!widget.isFirstAttempt)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppTokens.radiusMdAll,
                    ),
                    child: const Text('وضع التدريب', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            IconButton(
              icon: _isSharing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Icon(Icons.share_outlined),
              onPressed: _shareResult,
              tooltip: 'تحميل ومشاركة النتيجة',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + kToolbarHeight + AppTokens.spacing16,
            left: AppTokens.spacing16,
            right: AppTokens.spacing16,
            bottom: AppTokens.spacing16,
          ),
          child: Column(
            children: [
              _buildScoreSummary(context, isPassed),
              const SizedBox(height: AppTokens.spacing24),
              
              _buildStatsRow(context),
              const SizedBox(height: AppTokens.spacing32),
              
              if (wrongAnswerIndices.isNotEmpty) ...[
                _buildReviewHeader(context),
                const SizedBox(height: AppTokens.spacing16),
                ...wrongAnswerIndices.map((index) => _buildQuestionReview(context, index)),
              ] else if (widget.score == 100) ...[
                const Icon(Icons.stars, color: AppColors.primary, size: 48),
                const SizedBox(height: 16),
                const Text('أحسنت! جميع إجاباتك كانت صحيحة.', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
              
              const SizedBox(height: AppTokens.spacing32),
              _buildActionButtons(context),
              
              // Share Card (Hidden for capture)
              Offstage(
                offstage: true,
                child: RepaintBoundary(
                  key: _shareKey,
                  child: ResultShareCard(
                    studentName: studentName,
                    examTitle: widget.exam.title,
                    subject: widget.exam.subject,
                    score: widget.score,
                    accuracy: widget.accuracy,
                    speedBonus: widget.speedBonus,
                    grade: gradeText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGradeText(dynamic grade) {
    if (grade == null) return 'طالب عربيلوجيا';
    final g = grade is int ? grade : int.tryParse(grade.toString()) ?? 0;
    switch (g) {
      case 10: return 'الأولى باكالوريا';
      case 11: return 'الثانية ثانوي';
      case 12: return 'الثالثة ثانوي';
      default: return 'طالب عربيلوجيا';
    }
  }

  Widget _buildScoreSummary(BuildContext context, bool isPassed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.spacing32),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppTokens.radiusLgAll,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: widget.score / 100,
                  strokeWidth: 10,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.score}%',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const Text('الدرجة النهائية', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            isPassed ? 'تهانينا! لقد اجتزت الاختبار' : 'حاول مرة أخرى لتحسين مستواك',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        _buildStatCard(context, 'الأسئلة', '${widget.exam.questions.length}', Icons.quiz_outlined),
        const SizedBox(width: 8),
        _buildStatCard(context, 'الصحيحة', '${widget.correctCount}', Icons.check_circle_outline),
        const SizedBox(width: 8),
        _buildStatCard(context, 'الدقة', '${widget.accuracy}%', Icons.percent),
        const SizedBox(width: 8),
        _buildStatCard(context, 'المكافأة', '+${widget.speedBonus}', Icons.bolt, color: Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: AppTokens.radiusMdAll,
          border: Border.all(color: (color ?? AppColors.primary).withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color ?? AppColors.primary),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        const Text('مراجعة الأخطاء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: AppTokens.radiusFullAll,
          ),
          child: const Text('أخطاء فقط', style: TextStyle(color: AppColors.error, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildQuestionReview(BuildContext context, int index) {
    final question = widget.exam.questions[index];
    final selectedId = widget.userAnswers[index];
    final correctOption = question.options.firstWhere((o) => o.isCorrect);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppTokens.radiusLgAll,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: AppColors.error),
              const SizedBox(width: 8),
              Text('سؤال رقم ${index + 1}', style: const TextStyle(fontSize: 12, color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 8),
          Text(question.text, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildAnswerBox(context, 'إجابتك:', 
              selectedId == null ? 'لم تجب' : question.options.firstWhere((o) => o.id == selectedId).text, 
              false),
          const SizedBox(height: 8),
          _buildAnswerBox(context, 'الإجابة الصحيحة:', correctOption.text, true),
        ],
      ),
    );
  }

  Widget _buildAnswerBox(BuildContext context, String label, String text, bool isCorrect) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isCorrect ? AppColors.success : AppColors.error).withValues(alpha: 0.05),
        borderRadius: AppTokens.radiusMdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(text, style: TextStyle(fontWeight: FontWeight.w500, color: isCorrect ? AppColors.success : AppColors.error)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.goNamed('home'),
            child: const Text('العودة للرئيسية'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => context.pushReplacementNamed(
              'exam-session',
              pathParameters: {
                'examId': widget.exam.id,
                'subjectId': widget.exam.subjectId,
                'subjectName': widget.exam.subject,
              },
            ),
            child: const Text('إعادة الاختبار'),
          ),
        ),
      ],
    );
  }
}
