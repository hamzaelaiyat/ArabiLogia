import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/admin/widgets/anchored_dropdown.dart';

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
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing4,
        vertical: AppTokens.spacing2,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: AppTokens.radiusMdAll,
      ),
      child: Builder(
        builder: (innerContext) {
          return InkWell(
            borderRadius: AppTokens.radiusMdAll,
            onTap: () async {
              final selected = await showAnchoredMenu<String>(innerContext, [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('بدون فقرة'),
                ),
                ...passages.map(
                  (p) => DropdownMenuItem<String>(
                    value: p['id'],
                    child: Text(
                      p['title'] ?? 'فقرة',
                      style: const TextStyle(fontSize: AppTokens.fontSizeSm),
                    ),
                  ),
                ),
              ], color: isDark ? AppColors.bgDark : Colors.white);
              if (selected != null) {
                onPassageChanged(getPassageContent(selected));
              }
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    currentPassageId?.isEmpty == true ||
                            currentPassageId == null
                        ? 'اختر فقرة'
                        : (passages.firstWhere(
                                (p) => p['id'] == currentPassageId,
                                orElse: () => const {},
                              )['title'] ??
                              'فقرة'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: AppTokens.fontSizeSm,
                      color:
                          currentPassageId?.isEmpty == true ||
                              currentPassageId == null
                          ? AppColors.mutedColor(context)
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
