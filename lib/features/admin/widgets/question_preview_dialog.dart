import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';

class QuestionPreviewDialogs {
  static void show({
    required BuildContext context,
    required Question question,
    required int index,
    required bool isDark,
    required Color fgColor,
  }) {
    final isMobile = MediaQuery.of(context).size.width < AppTokens.breakpointTablet;
    if (isMobile) {
      _showMobile(context, question, index, isDark, fgColor);
    } else {
      _showDesktop(context, question, index, isDark, fgColor);
    }
  }

  static void _showMobile(BuildContext context, Question question, int index, bool isDark, Color fgColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232527) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'معاينة السؤال ${index + 1}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: fgColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: fgColor),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF111315) : const Color(0xFFF0F4F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          question.text.isEmpty
                              ? 'السؤال يظهر هنا...'
                              : question.text,
                          style: const TextStyle(fontSize: 16, height: 1.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'الخيارات:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: fgColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(question.options.length, (optIndex) {
                      if (optIndex >= question.options.length) return const SizedBox.shrink();
                      final option = question.options[optIndex];
                      final labels = ['أ', 'ب', 'ج', 'د'];
                      final label = optIndex < labels.length ? labels[optIndex] : '${optIndex + 1}';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: option.isCorrect
                                    ? const Color(0xFF4CAF50)
                                    : (isDark ? Colors.white10 : Colors.black12),
                              ),
                              child: option.isCorrect
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : Center(
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white38 : Colors.black26,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option.text.isEmpty ? 'الخيار $label' : option.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: option.text.isEmpty
                                      ? AppColors.mutedColor(context)
                                      : fgColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showDesktop(BuildContext context, Question question, int index, bool isDark, Color fgColor) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          height: 500,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232527) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'معاينة السؤال ${index + 1}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: fgColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: Icon(Icons.close, color: fgColor),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF111315) : const Color(0xFFF0F4F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 16, height: 1.6),
                              children: parseQuestionText(
                                question.text.isEmpty
                                    ? 'السؤال يظهر هنا...'
                                    : question.text,
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'الخيارات:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: fgColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(question.options.length, (optIndex) {
                        if (optIndex >= question.options.length) return const SizedBox.shrink();
                        final option = question.options[optIndex];
                        final labels = ['أ', 'ب', 'ج', 'د'];
                        final label = optIndex < labels.length ? labels[optIndex] : '${optIndex + 1}';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: option.isCorrect
                                      ? const Color(0xFF4CAF50)
                                      : (isDark ? Colors.white10 : Colors.black12),
                                ),
                                child: option.isCorrect
                                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                                    : Center(
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white38 : Colors.black26,
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: option.text.isEmpty
                                          ? AppColors.mutedColor(context)
                                          : fgColor,
                                    ),
                                    children: parseQuestionText(
                                      option.text.isEmpty ? 'الخيار $label' : option.text,
                                      isDark: isDark,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
