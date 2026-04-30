import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final QuestionSettings? settings;
  final int index;
  final List<Map<String, String>> passages;
  final String? Function(String?) getPassageValue;
  final String? Function(String?) getPassageContent;
  final bool Function(String?) isSavedPassage;
  final bool isMobile;
  final VoidCallback onDelete;
  final Function(Question) onUpdate;
  final Function(QuestionSettings)? onSettingsUpdate;

  const QuestionCard({
    super.key,
    required this.question,
    this.settings,
    required this.index,
    required this.passages,
    required this.getPassageValue,
    required this.getPassageContent,
    required this.isSavedPassage,
    this.isMobile = false,
    required this.onDelete,
    required this.onUpdate,
    this.onSettingsUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'سؤال',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.mutedColor(context),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'حذف السؤال',
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacing16),

          // Question text input with underline
          _buildUnderlineInput(
            context: context,
            value: question.text,
            hint: 'ما هو السؤال؟',
            isDark: isDark,
            onChanged: (val) =>
                onUpdate(_copyWithQuestion(question, text: val)),
          ),

          // Passage selector dropdown
          if (passages.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spacing16),
            _buildPassageSelector(context, isDark),
          ],

          const SizedBox(height: AppTokens.spacing16),

          // Options section - stacked vertically on phone
          Text(
            'حدد أ ب ج أو د',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedColor(context),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            4,
            (optIndex) => _buildOptionRow(optIndex, isDark, context),
          ),
        ],
      ),
    );
  }

  Widget _buildUnderlineInput({
    required BuildContext context,
    required String value,
    required String hint,
    required bool isDark,
    required Function(String) onChanged,
  }) {
    // Use a key to force rebuild when value changes externally
    return _QuestionInputWithToolbar(
      key: ValueKey('question_input_${question.text.hashCode}'),
      value: value,
      hint: hint,
      onChanged: onChanged,
    );
  }

  Widget _buildPassageSelector(BuildContext context, bool isDark) {
    final currentPassageId = getPassageValue(question.passage);
    final hasExistingPassage = question.passage?.isNotEmpty == true;
    final selectedPassageId =
        hasExistingPassage && !passages.any((p) => p['id'] == currentPassageId)
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
                child: Text(p['title'] ?? '', overflow: TextOverflow.ellipsis),
              ),
            ),
            if (hasExistingPassage && currentPassageId?.isNotEmpty == true)
              const DropdownMenuItem<String>(
                value: '__existing__',
                child: Text(
                  'قرائة محفوظة',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
          onChanged: (value) {
            if (value == null || value.isEmpty) {
              onUpdate(_copyWithQuestion(question, passage: ''));
            } else if (value == '__existing__') {
              return;
            } else {
              final passageContent = getPassageContent(value);
              onUpdate(
                _copyWithQuestion(question, passage: passageContent ?? ''),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildOptionRow(int optIndex, bool isDark, BuildContext context) {
    final option = optIndex < question.options.length
        ? question.options[optIndex]
        : Option(id: 'o${optIndex + 1}', text: '', isCorrect: false);
    final isCorrect = option.isCorrect;
    final correctIdx = question.options.indexWhere((o) => o.isCorrect);
    final isSelectedCorrect = correctIdx >= 0 && correctIdx == optIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Radio button
          GestureDetector(
            onTap: () {
              final updatedOpts = <Option>[];
              for (int i = 0; i < question.options.length; i++) {
                updatedOpts.add(
                  Option(
                    id: question.options[i].id,
                    text: question.options[i].text,
                    isCorrect: i == optIndex,
                  ),
                );
              }
              onUpdate(_copyWithQuestion(question, options: updatedOpts));
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelectedCorrect ? Colors.green : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelectedCorrect ? Colors.green : Colors.transparent,
              ),
              child: isSelectedCorrect
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Option letter (A, B, C, D)
          Text(
            ['أ', 'ب', 'ج', 'د'][optIndex],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelectedCorrect ? Colors.green : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          // Underline input - RTL support
          Expanded(
            child: TextFormField(
              initialValue: option.text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.foreground(context),
              ),
              decoration: InputDecoration(
                hintText: 'إجابة...',
                hintStyle: TextStyle(
                  color: AppColors.mutedColor(context),
                  fontSize: 13,
                ),
                filled: false,
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.mutedColor(context)),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.mutedColor(context)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isSelectedCorrect ? Colors.green : AppColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
              onChanged: (val) {
                final updatedOpts = <Option>[];
                for (int i = 0; i < question.options.length; i++) {
                  updatedOpts.add(
                    Option(
                      id: question.options[i].id,
                      text: i == optIndex ? val : question.options[i].text,
                      isCorrect: question.options[i].isCorrect,
                    ),
                  );
                }
                onUpdate(_copyWithQuestion(question, options: updatedOpts));
              },
            ),
          ),
        ],
      ),
    );
  }

  Question _copyWithQuestion(
    Question q, {
    String? id,
    String? text,
    String? passage,
    List<Option>? options,
  }) {
    return Question(
      id: id ?? const Uuid().v4(),
      text: text ?? q.text,
      passage: passage ?? q.passage,
      options: options ?? q.options,
    );
  }
}

/// Stateful widget for question input with formatting toolbar
/// Properly manages TextEditingController for RTL text handling
class _QuestionInputWithToolbar extends StatefulWidget {
  final String value;
  final String hint;
  final Function(String) onChanged;

  const _QuestionInputWithToolbar({
    super.key,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_QuestionInputWithToolbar> createState() =>
      _QuestionInputWithToolbarState();
}

class _QuestionInputWithToolbarState extends State<_QuestionInputWithToolbar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _QuestionInputWithToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if value changed externally (not from our own edits)
    if (widget.value != _controller.text && widget.value != oldWidget.value) {
      final selection = _controller.selection;
      _controller.text = widget.value;
      // Try to restore cursor position if valid
      if (selection.isValid && selection.end <= widget.value.length) {
        _controller.selection = selection;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _wrapSelection(String prefix, String suffix) {
    final selection = _controller.selection;
    if (!selection.isValid || selection.start == selection.end) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدد النص المطلوب أولاً'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final text = _controller.text;
    final selectedText = text.substring(selection.start, selection.end);
    final newText =
        text.substring(0, selection.start) +
        prefix +
        selectedText +
        suffix +
        text.substring(selection.end);

    _controller.text = newText;
    widget.onChanged(newText);

    // Position cursor after the inserted text
    _controller.selection = TextSelection.collapsed(
      offset: selection.end + prefix.length + suffix.length,
    );
  }

  void _applyColor(int colorIndex) {
    _wrapSelection('{$colorIndex}', '{$colorIndex}');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Formatting toolbar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildToolbarButton(
                icon: Icons.format_bold,
                label: 'عريض',
                onTap: () => _wrapSelection('**', '**'),
              ),
              const SizedBox(width: 8),
              _buildToolbarButton(
                icon: Icons.format_italic,
                label: 'مائل',
                onTap: () => _wrapSelection('*', '*'),
              ),
              const SizedBox(width: 8),
              _buildColorPicker(),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // RTL TextField
        Directionality(
          textDirection: TextDirection.rtl,
          child: TextFormField(
            controller: _controller,
            maxLines: 3,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: AppTokens.fontSizeLg,
              color: AppColors.foreground(context),
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: AppColors.mutedColor(context),
                fontSize: AppTokens.fontSizeLg,
              ),
              filled: false,
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.mutedColor(context)),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.mutedColor(context)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: widget.onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.mutedColor(context)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.foreground(context)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.foreground(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return PopupMenuButton<int>(
      offset: const Offset(0, 40),
      tooltip: 'لون النص',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.mutedColor(context)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.palette, size: 16, color: AppColors.foreground(context)),
            const SizedBox(width: 4),
            Text(
              'لون',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.foreground(context),
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => List.generate(10, (index) {
        return PopupMenuItem<int>(
          value: index,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: QuestionTextStyle.textColors[index],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                QuestionTextStyle.colorNames[index],
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      }),
      onSelected: _applyColor,
    );
  }
}
