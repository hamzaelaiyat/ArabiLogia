import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/score_summary_widget.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/stats_row_widget.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/question_review_widget.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/action_buttons_widget.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/result_share_card.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
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
          _shareKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        debugPrint('Failed to convert image to byte data');
        return;
      }
      Uint8List pngBytes = byteData.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = await File(
        '${directory.path}/score_share.png',
      ).create();
      await imagePath.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text:
            'لقد حصلت على ${widget.score}% في اختبار ${widget.exam.title} على تطبيق عربيلوجيا! 🎉',
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
    final studentName =
        userMetadata?['full_name'] ??
        userMetadata?['username'] ??
        'طالب عربيلوجيا';
    final gradeRaw = userMetadata?['grade'];
    final gradeText = _getGradeText(gradeRaw);

    final wrongAnswerIndices = [];
    for (int i = 0; i < widget.exam.questions.length; i++) {
      final question = widget.exam.questions[i];
      final selectedId = widget.userAnswers[i];
      final correctOption = question.options.cast<Option?>().firstWhere(
        (o) => o?.isCorrect == true,
        orElse: () => null,
      );
      final correctId = correctOption?.id;
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppTokens.radiusMdAll,
                    ),
                    child: const Text(
                      'وضع التدريب',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_outlined),
              onPressed: _shareResult,
              tooltip: 'تحميل ومشاركة النتيجة',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            top:
                MediaQuery.paddingOf(context).top +
                kToolbarHeight +
                AppTokens.spacing16,
            left: AppTokens.spacing16,
            right: AppTokens.spacing16,
            bottom: AppTokens.spacing16,
          ),
              child: Column(
                children: [
                  ScoreSummaryWidget(
                    score: widget.score,
                    isPassed: isPassed,
                  ),
                  const SizedBox(height: AppTokens.spacing24),

                  StatsRowWidget(
                    totalQuestions: widget.exam.questions.length,
                    correctCount: widget.correctCount,
                    accuracy: widget.accuracy,
                    speedBonus: widget.speedBonus,
                  ),
                  const SizedBox(height: AppTokens.spacing32),

                  if (wrongAnswerIndices.isNotEmpty) ...[
                    const ReviewHeaderWidget(),
                    const SizedBox(height: AppTokens.spacing16),
                    ...wrongAnswerIndices.map(
                      (index) => QuestionReviewCardWidget(
                        question: widget.exam.questions[index],
                        index: index,
                        selectedId: widget.userAnswers[index],
                      ),
                    ),
                  ] else if (widget.score == 100) ...[
                    const Icon(Icons.stars, color: AppColors.primary, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'أحسنت! جميع إجاباتك كانت صحيحة.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],

                  const SizedBox(height: AppTokens.spacing32),
                  ActionButtonsWidget(
                    onHomePressed: () => context.goNamed('home'),
                    onRetakePressed: () => context.pushReplacementNamed(
                      'exam-interaction',
                      pathParameters: {
                        'id': widget.exam.id,
                        'subjectId': widget.exam.subjectId,
                        'subjectName': widget.exam.subject,
                      },
                    ),
                  ),

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
      case 10:
        return 'الأولى باكالوريا';
      case 11:
        return 'الثانية ثانوي';
      case 12:
        return 'الثالثة ثانوي';
      default:
        return 'طالب عربيلوجيا';
    }
  }

}
