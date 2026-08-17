import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class QuestionPassageSelector extends StatelessWidget {
  final List<Map<String, String>> passages;
  final String? Function(String?) getPassageValue;
  final String? Function(String?) getPassageContent;
  final String? passageQuestionRef;
  final ValueChanged<String?> onPassageChanged;

  const QuestionPassageSelector({
    super.key,
    required this.passages,
    required this.getPassageValue,
    required this.getPassageContent,
    required this.passageQuestionRef,
    required this.onPassageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPassageId = getPassageValue(passageQuestionRef);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: AppTokens.radiusMdAll,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (currentPassageId?.isEmpty == true) ? null : currentPassageId,
          hint: Text(
            'اختر فقرة',
            style: TextStyle(
              fontSize: AppTokens.fontSizeSm,
              color: AppColors.mutedColor(context),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          dropdownColor: isDark ? AppColors.bgDark : Colors.white,
          items: [
            const DropdownMenuItem<String>(value: '', child: Text('بدون فقرة')),
            ...passages.map(
              (p) => DropdownMenuItem<String>(
                value: p['id'],
                child: Text(
                  p['title'] ?? 'فقرة',
                  style: const TextStyle(fontSize: AppTokens.fontSizeSm),
                ),
              ),
            ),
          ],
          onChanged: (val) {
            onPassageChanged(getPassageContent(val));
          },
        ),
      ),
    );
  }
}
