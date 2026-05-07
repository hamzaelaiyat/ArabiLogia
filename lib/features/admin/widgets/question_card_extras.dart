import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';

class QuestionCardExtras {
  static Widget buildPassageSelector({
    required BuildContext context,
    required bool isDark,
    required String? currentPassageId,
    required List<Map<String, String>> passages,
    required bool hasExistingPassage,
    required Function(String?) onPassageChanged,
  }) {
    final selectedPassageId = hasExistingPassage &&
            !passages.any((p) => p['id'] == currentPassageId)
        ? '__existing__'
        : (currentPassageId ?? '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPassageId.isEmpty ? null : selectedPassageId,
          isExpanded: true,
          hint: Text(
            'اختر فقرة (اختياري)',
            style: TextStyle(color: Colors.grey[400]),
          ),
          dropdownColor: isDark ? AppColors.bgDark : Colors.white,
          items: [
            const DropdownMenuItem<String>(value: '', child: Text('بد فقرة')),
            ...passages.map(
              (p) => DropdownMenuItem<String>(
                value: p['id'],
                child: Text(
                  p['title'] ?? 'فقرة بدون عنوان',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (hasExistingPassage &&
                !passages.any((p) => p['id'] == currentPassageId))
              const DropdownMenuItem<String>(
                value: '__existing__',
                child: Text('فقرة محفوظة'),
              ),
          ],
          onChanged: (val) {
            if (val == '__existing__') {
              onPassageChanged(null);
            } else {
              onPassageChanged(val?.isEmpty == true ? null : val);
            }
          },
        ),
      ),
    );
  }
}