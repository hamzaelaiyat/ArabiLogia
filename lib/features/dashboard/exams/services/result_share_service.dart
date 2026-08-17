import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arabilogia/core/utils/grade_utils.dart';
import '../widgets/result_share_card.dart';

/// Generates and shares exam result images instead of raw HTML.
///
/// Uses a [RepaintBoundary] + [OverlayEntry] pattern to render a
/// [ResultShareCard] widget off-screen, capture it as a PNG image,
/// and share via the system share sheet.
class ResultShareService {
  ResultShareService._();

  /// Builds a [ResultShareCard], renders it to a PNG image, and shares it.
  ///
  /// On web platforms, falls back to plain-text sharing since
  /// [RenderRepaintBoundary.toImage] is not available there.
  static Future<void> shareExamResult({
    required BuildContext context,
    required String? fullName,
    required String? username,
    required dynamic gradeRaw,
    required int score,
    required int accuracy,
    required int speedBonus,
    required int correctCount,
    required String examTitle,
    required String examId,
    required int passPercentage,
    required int totalQuestions,
  }) async {
    final studentName = fullName ?? username ?? 'طالب عربيلوجيا';
    final gradeText = getGradeText(gradeRaw, fallback: 'طالب عربيلوجيا');
    final isPassed = score >= passPercentage;
    final subject = 'نتيجتي في اختبار $examTitle - عربيلوجيا';
    final shareText = _buildShareText(
      studentName: studentName,
      examTitle: examTitle,
      score: score,
      accuracy: accuracy,
      speedBonus: speedBonus,
      correctCount: correctCount,
      totalQuestions: totalQuestions,
      isPassed: isPassed,
    );

    // Web: RepaintBoundary.toImage is not available
    if (kIsWeb) {
      final isDesktopWeb = switch (defaultTargetPlatform) {
        TargetPlatform.android || TargetPlatform.iOS => false,
        _ => true,
      };

      if (isDesktopWeb) {
        await launchUrl(
          Uri.parse(
            'data:text/plain;charset=utf-8,${Uri.encodeComponent(shareText)}',
          ),
          mode: LaunchMode.platformDefault,
        );
      } else {
        await Share.share(shareText, subject: subject);
      }
      return;
    }

    // Native path: render the card off-screen to PNG
    try {
      final pngBytes = await _renderCardToPng(
        context: context,
        studentName: studentName,
        examTitle: examTitle,
        score: score,
        accuracy: accuracy,
        speedBonus: speedBonus,
        correctCount: correctCount,
        totalQuestions: totalQuestions,
        grade: gradeText,
        isPassed: isPassed,
      );

      if (pngBytes == null) {
        await Share.share(shareText, subject: subject);
        return;
      }

      // Save to temp file and share via XFile
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/arabilogia_result_$examId.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject,
        text: shareText,
      );
    } catch (e) {
      debugPrint('ResultShareService error: $e');
      await Share.share(shareText, subject: subject);
    }
  }

  /// Renders the [ResultShareCard] to a PNG byte array using a temporary
  /// [OverlayEntry] + [Offstage] widget tree.
  static Future<Uint8List?> _renderCardToPng({
    required BuildContext context,
    required String studentName,
    required String examTitle,
    required int score,
    required int accuracy,
    required int speedBonus,
    required int correctCount,
    required int totalQuestions,
    required String grade,
    required bool isPassed,
  }) async {
    final captureKey = GlobalKey();

    // Insert a hidden Offstage entry into the overlay to render the card
    // without showing it to the user.
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Offstage(
        child: SizedBox(
          width: 600,
          height: 980,
          child: RepaintBoundary(
            key: captureKey,
            child: Material(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ResultShareCard(
                  studentName: studentName,
                  examTitle: examTitle,
                  score: score,
                  accuracy: accuracy,
                  speedBonus: speedBonus,
                  correctCount: correctCount,
                  totalQuestions: totalQuestions,
                  grade: grade,
                  isPassed: isPassed,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(entry);

    // Wait for next frame so the widget is laid out and painted
    await WidgetsBinding.instance.endOfFrame;

    try {
      final boundary = captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('ResultShareService._renderCardToPng error: $e');
      return null;
    } finally {
      entry.remove();
    }
  }

  /// Builds a plain-text fallback share message.
  static String _buildShareText({
    required String studentName,
    required String examTitle,
    required int score,
    required int accuracy,
    required int speedBonus,
    required int correctCount,
    required int totalQuestions,
    required bool isPassed,
  }) {
    final passText = isPassed ? '✅ تم الاجتياز' : '❌ لم يتم الاجتياز';
    return '''
📚 عربيلوجيا - مجموعة وليد قطب

نتيجتي في اختبار: $examTitle
الاسم: $studentName
الدرجة: $score%
الدقة: $accuracy%
النقاط الإضافية: +$speedBonus
الإجابات الصحيحة: $correctCount/$totalQuestions
$passText

— عربيلوجيا
''';
  }
}
