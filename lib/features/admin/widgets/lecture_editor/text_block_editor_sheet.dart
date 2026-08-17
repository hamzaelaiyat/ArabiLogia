import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/lectures/models/lecture.dart';

class TextBlockEditorSheet extends StatefulWidget {
  final LectureContentBlock? existingBlock;
  final int? index;
  final void Function(LectureContentBlock, int?) onSave;

  const TextBlockEditorSheet({
    super.key,
    this.existingBlock,
    this.index,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    LectureContentBlock? existingBlock,
    int? index,
    required void Function(LectureContentBlock, int?) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => TextBlockEditorSheet(
        existingBlock: existingBlock,
        index: index,
        onSave: onSave,
      ),
    );
  }

  @override
  State<TextBlockEditorSheet> createState() => _TextBlockEditorSheetState();
}

class _TextBlockEditorSheetState extends State<TextBlockEditorSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existingBlock?.content ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insertMarkdown(String tag, {String? closeTag}) {
    final text = _controller.text;
    final selection = _controller.selection;
    if (selection.start == -1 || selection.end == -1) {
      _controller.text = text + tag + (closeTag ?? tag);
      return;
    }
    final selectedText = text.substring(selection.start, selection.end);
    final replacement = tag + selectedText + (closeTag ?? tag);
    final newText = text.replaceRange(selection.start, selection.end, replacement);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + tag.length + selectedText.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existingBlock = widget.existingBlock;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                existingBlock != null ? 'تعديل المحتوى النصي' : 'إضافة محتوى نصي',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.format_bold),
                tooltip: 'عريض',
                onPressed: () => setState(() => _insertMarkdown('**')),
              ),
              IconButton(
                icon: const Icon(Icons.format_italic),
                tooltip: 'مائل',
                onPressed: () => setState(() => _insertMarkdown('*')),
              ),
              IconButton(
                icon: const Icon(Icons.format_underlined),
                tooltip: 'تحته خط',
                onPressed: () => setState(() => _insertMarkdown('<u>', closeTag: '</u>')),
              ),
              IconButton(
                icon: const Icon(Icons.format_strikethrough),
                tooltip: 'يتوسطه خط',
                onPressed: () => setState(() => _insertMarkdown('~~')),
              ),
              const Spacer(),
              const Icon(Icons.info_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              const Text('يدعم لغة Markdown', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controller,
            maxLines: 8,
            autofocus: true,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'اكتب كلام هنا...',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final text = _controller.text.trim();
              if (text.isNotEmpty) {
                final block = LectureContentBlock(
                  id: existingBlock?.id ?? const Uuid().v4(),
                  type: BlockType.text,
                  content: text,
                );
                widget.onSave(block, widget.index);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(existingBlock != null ? 'تحديث النص' : 'إضافة النص'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
