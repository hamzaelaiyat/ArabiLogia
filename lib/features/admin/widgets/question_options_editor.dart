import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';

class QuestionOptionsEditor extends StatelessWidget {
  final List<TextEditingController> optionControllers;
  final List<Option> options;
  final bool isMobile;
  final bool isDark;
  final Function(int, String) onOptionTextChanged;
  final Function(int) onCorrectAnswerToggled;

  const QuestionOptionsEditor({
    super.key,
    required this.optionControllers,
    required this.options,
    required this.isMobile,
    required this.isDark,
    required this.onOptionTextChanged,
    required this.onCorrectAnswerToggled,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return _buildMobileOptionsSection(context);
    }
    return _buildDesktopOptionsSection(context);
  }

  Widget _buildMobileOptionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(4, (optIndex) => _buildMobileOptionRow(optIndex, context)),
      ],
    );
  }

  Widget _buildMobileOptionRow(int optIndex, BuildContext context) {
    final labels = ['أ', 'ب', 'ج', 'د'];
    final label = optIndex < labels.length ? labels[optIndex] : '${optIndex + 1}';
    final option = options.length > optIndex ? options[optIndex] : null;
    final isCorrect = option?.isCorrect ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onCorrectAnswerToggled(optIndex),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCorrect
                    ? const Color(0xFF4CAF50)
                    : (isDark ? Colors.white10 : Colors.black12),
              ),
              child: isCorrect
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: optionControllers[optIndex],
              onChanged: (val) => onOptionTextChanged(optIndex, val),
              maxLines: null,
              minLines: 1,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'الخيار $label',
                hintStyle: TextStyle(color: AppColors.mutedColor(context)),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopOptionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'حدد أ ب ج أو د',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.mutedColor(context),
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(4, (optIndex) => _buildOptionRow(optIndex, context)),
      ],
    );
  }

  Widget _buildOptionRow(int optIndex, BuildContext context) {
    final potato = context.watch<PotatoModeProvider>();
    final optionDuration = potato.animationsEnabled
        ? AppTokens.durationSm
        : Duration.zero;
    final labels = ['أ', 'ب', 'ج', 'د'];
    final label = optIndex < labels.length ? labels[optIndex] : '${optIndex + 1}';
    final option = options.length > optIndex ? options[optIndex] : null;
    final isCorrect = option?.isCorrect ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spacing12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => onCorrectAnswerToggled(optIndex),
            child: AnimatedContainer(
              duration: optionDuration,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCorrect
                    ? const Color(0xFF4CAF50)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
              ),
              child: isCorrect
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
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: optionControllers[optIndex],
              onChanged: (val) => onOptionTextChanged(optIndex, val),
              maxLines: null,
              minLines: 1,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'أدخل الخيار $label...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedColor(context).withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF111315) : const Color(0xFFF0F4F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
