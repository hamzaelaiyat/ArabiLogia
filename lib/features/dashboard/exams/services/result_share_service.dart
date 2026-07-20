import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arabilogia/core/utils/grade_utils.dart';
import '../utils/result_html_generator.dart';

class ResultShareService {
  ResultShareService._();

  static Future<void> shareExamResult({
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
  }) async {
    final studentName = fullName ?? username ?? 'طالب عربيلوجيا';
    final gradeText = getGradeText(gradeRaw, fallback: 'طالب عربيلوجيا');

    final html = generateResultHtml(
      studentName: studentName,
      gradeText: gradeText,
      score: score,
      accuracy: accuracy,
      speedBonus: speedBonus,
      correctCount: correctCount,
      examTitle: examTitle,
      passPercentage: passPercentage,
    );
    final subject = 'نتيجتي في اختبار $examTitle - عربيلوجيا';

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
      final file = File('${dir.path}/exam_result_$examId.html');
      await file.writeAsString(html);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject,
      );
    } else {
      await Share.share(html, subject: subject);
    }
  }
}
