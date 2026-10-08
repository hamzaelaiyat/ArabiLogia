import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/admin/widgets/anchored_dropdown.dart';

class QuestionCardExtras {
  static Widget buildPassageSelector({
    required BuildContext context,
    required bool isDark,
    required String? currentPassageId,
    required List<Map<String, String>> passages,
    required bool hasExistingPassage,
    required Function(String?) onPassageChanged,
  }) {
    final selectedPassageId =
        hasExistingPassage && !passages.any((p) => p['id'] == currentPassageId)
        ? '__existing__'
        : (currentPassageId ?? '');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing8,
        vertical: AppTokens.spacing4,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Builder(
        builder: (innerContext) {
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final selected = await showAnchoredMenu<String>(innerContext, [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('بد فقرة'),
                ),
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
              ]);
              if (selected == null) return;
              if (selected == '__existing__') {
                onPassageChanged(null);
              } else {
                onPassageChanged(selected.isEmpty ? null : selected);
              }
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedPassageId == '__existing__'
                        ? 'فقرة محفوظة'
                        : (currentPassageId?.isEmpty == true ||
                              currentPassageId == null)
                        ? 'اختر فقرة (اختياري)'
                        : (passages.firstWhere(
                                (p) => p['id'] == currentPassageId,
                                orElse: () => const {},
                              )['title'] ??
                              'فقرة'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color:
                          selectedPassageId == '__existing__' ||
                              currentPassageId?.isEmpty == false
                          ? (Theme.of(innerContext).brightness ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black87)
                          : Colors.grey[400],
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
