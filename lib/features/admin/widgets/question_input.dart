import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';

class QuestionInput extends StatefulWidget {
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onPreviewToggle;
  final bool showPreviewToggle;

  const QuestionInput({
    super.key,
    required this.value,
    this.hint = '',
    required this.onChanged,
    this.onPreviewToggle,
    this.showPreviewToggle = false,
  });

  @override
  State<QuestionInput> createState() => QuestionInputState();
}

class QuestionInputState extends State<QuestionInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant QuestionInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _wrapSelection(String prefix, String suffix) {
    final text = _controller.text;
    final selection = _controller.selection;

    if (selection.isCollapsed) {
      final newText = text.substring(0, selection.start) +
          prefix +
          suffix +
          text.substring(selection.start);
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: selection.start + prefix.length,
      );
    } else {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.substring(0, selection.start) +
          prefix +
          selectedText +
          suffix +
          text.substring(selection.end);
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: selection.start + prefix.length + selectedText.length,
      );
    }
    widget.onChanged(_controller.text);
  }

  void _applyColor(int colorIndex) {
    final tag = '{\$$colorIndex}';
    _wrapSelection(tag, tag);
  }

  String get _text => _controller.text;

  void wrapSelection(String prefix, String suffix) {
    _wrapSelection(prefix, suffix);
  }

  void applyColor(int colorIndex) {
    _applyColor(colorIndex);
  }

  @override
  Widget build(BuildContext context) {
    return _buildEditFieldWithStack();
  }

  Widget _buildEditFieldWithStack() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          maxLines: 5,
          minLines: 3,
          textAlignVertical: TextAlignVertical.top,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 15, height: 1.5),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: AppColors.mutedColor(context).withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.fromLTRB(60, 16, 16, 40),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: _buildFormattingToolbar(context, isDark),
        ),
      ],
    );
  }

  Widget _buildFormattingToolbar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolIcon(
            Icons.format_bold_rounded,
            'عريض',
            isDark,
            () => wrapSelection('**', '**'),
          ),
          _buildToolIcon(
            Icons.format_underlined_rounded,
            'تحته خط',
            isDark,
            () => wrapSelection('__', '__'),
          ),
          _buildColorTool(isDark),
        ],
      ),
    );
  }

  Widget _buildToolIcon(IconData icon, String tooltip, bool isDark, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTokens.radiusSmAll,
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(
              icon,
              size: 18,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorTool(bool isDark) {
    return PopupMenuButton<int>(
      offset: const Offset(0, 32),
      tooltip: 'لون النص',
      onSelected: (index) => applyColor(index),
      itemBuilder: (context) => List.generate(10, (index) {
        return PopupMenuItem<int>(
          value: index,
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: QuestionTextStyle.textColors[index],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                QuestionTextStyle.colorNames[index],
                style: const TextStyle(fontSize: AppTokens.fontSizeSm),
              ),
            ],
          ),
        );
      }),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Icon(
          Icons.palette_outlined,
          size: 18,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  }