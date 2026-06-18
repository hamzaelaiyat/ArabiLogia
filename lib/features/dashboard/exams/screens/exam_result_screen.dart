import 'dart:convert';
import 'dart:io';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/score_summary_widget.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/stats_row_widget.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/question_review_widget.dart';
import 'package:arabilogia/features/dashboard/exams/widgets/action_buttons_widget.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isSharing = false;

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String _generateResultHtml({
    required String studentName,
    required String gradeText,
  }) {
    final isPassed = widget.score >= 50;
    final passText = isPassed ? '✅ تم الاجتياز' : '❌ لم يتم الاجتياز';
    return '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>نتيجة الاختبار - عربيلوجيا</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Segoe UI',Tahoma,sans-serif;background:#f5f5f5;display:flex;justify-content:center;align-items:center;min-height:100vh;padding:20px;direction:rtl}
.card{background:#191B1D;border-radius:24px;padding:40px 32px;max-width:420px;width:100%;text-align:center;box-shadow:0 8px 32px rgba(0,0,0,0.3);border:1px solid rgba(255,255,255,0.08)}
.logo{width:60px;height:60px;margin:0 auto 12px;background:#EB8A00;border-radius:16px;display:flex;align-items:center;justify-content:center;font-size:28px;color:#fff;font-weight:bold;line-height:1}
.brand-text h1{color:#EB8A00;font-size:20px;font-weight:bold;margin:0}
.brand-text p{color:rgba(255,255,255,0.6);font-size:11px;margin:4px 0 0}
.achievement{color:#fff;font-size:18px;margin:20px 0 4px;font-weight:bold}
.exam-title{color:#EB8A00;font-size:22px;font-weight:bold;margin:0 0 28px;line-height:1.3}
.score-wrap{width:130px;height:130px;border-radius:50%;background:conic-gradient(#EB8A00 ${widget.score}%,rgba(255,255,255,0.08) ${widget.score}%);display:flex;flex-direction:column;align-items:center;justify-content:center;margin:0 auto 24px;position:relative}
.score-wrap::before{content:'';position:absolute;inset:5px;border-radius:50%;background:#191B1D}
.score-number{font-size:34px;font-weight:bold;color:#fff;position:relative;z-index:1;line-height:1}
.score-label{font-size:10px;color:rgba(255,255,255,0.7);position:relative;z-index:1;margin-top:2px}
.stats{background:rgba(255,255,255,0.04);border-radius:14px;padding:16px 20px;display:flex;justify-content:space-around;margin-bottom:24px;border:1px solid rgba(255,255,255,0.08)}
.stat{text-align:center}
.stat-value{color:#EB8A00;font-size:18px;font-weight:bold}
.stat-label{color:rgba(255,255,255,0.5);font-size:11px;margin-top:2px}
.stat-divider{width:1px;background:rgba(255,255,255,0.15);margin:0 8px}
.info{margin-bottom:8px}
.student-name{color:#fff;font-size:16px;font-weight:500}
.grade-text{color:rgba(255,255,255,0.5);font-size:12px;margin-top:2px}
.badge{display:inline-block;padding:6px 16px;border-radius:20px;font-size:13px;font-weight:600;margin-top:16px;${isPassed ? 'background:#34C75920;color:#34C759;border:1px solid #34C75940' : 'background:#FF3B3020;color:#FF3B30;border:1px solid #FF3B3040'}}
.footer{color:rgba(255,255,255,0.25);font-size:10px;margin-top:24px}
</style>
</head>
<body>
<div class="card">
<div class="logo">ع</div>
<div class="brand-text"><h1>عربيلوجيا</h1><p>مجموعة وليد قطب</p></div>
<div class="achievement">لقد أتممت الاختبار بنجاح!</div>
<div class="exam-title">${_escapeHtml(widget.exam.title)}</div>
<div class="score-wrap"><div class="score-number">${widget.score}%</div><div class="score-label">الدرجة النهائية</div></div>
<div class="stats">
<div class="stat"><div class="stat-value">${widget.accuracy}%</div><div class="stat-label">الدقة</div></div>
<div class="stat-divider"></div>
<div class="stat"><div class="stat-value">+${widget.speedBonus}</div><div class="stat-label">مكافأة السرعة</div></div>
<div class="stat-divider"></div>
<div class="stat"><div class="stat-value">${widget.correctCount}</div><div class="stat-label">الإجابات الصحيحة</div></div>
</div>
<div class="info"><div class="student-name">${_escapeHtml(studentName)}</div><div class="grade-text">$gradeText</div></div>
<div class="badge">$passText</div>
<div class="footer">عربيلوجيا — مجموع وليد قطب</div>
</div>
</body>
</html>''';
  }

  Future<void> _shareResult() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userMetadata = authProvider.state.user?.userMetadata;
      final studentName =
          userMetadata?['full_name'] ??
          userMetadata?['username'] ??
          'طالب عربيلوجيا';
      final gradeRaw = userMetadata?['grade'];
      final gradeText = _getGradeText(gradeRaw);

      final html = _generateResultHtml(
        studentName: studentName,
        gradeText: gradeText,
      );
      final subject = 'نتيجتي في اختبار ${widget.exam.title} - عربيلوجيا';

      if (kIsWeb) {
        final isDesktopWeb = switch (defaultTargetPlatform) {
          TargetPlatform.android || TargetPlatform.iOS => false,
          _ => true,
        };

        if (isDesktopWeb) {
          final encoded = base64Encode(utf8.encode(html));
          await launchUrl(
            Uri.parse('data:text/html;base64,$encoded'),
            mode: LaunchMode.platformDefault,
          );
        } else {
          await Share.share(html, subject: subject);
        }
      } else if (Platform.isAndroid) {
        await Share.share(html, subject: subject);
      } else if (Platform.isLinux) {
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/exam_result_${widget.exam.id}.html',
        );
        await file.writeAsString(html);
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: subject,
        );
      } else {
        await Share.share(html, subject: subject);
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPassed = widget.score >= 50;
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
                      pathParameters: {'id': widget.exam.id},
                      extra: {
                        'subjectId': widget.exam.subjectId,
                        'subjectName': widget.exam.subject,
                      },
                    ),
                  ),
                ],),
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
