import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/admin/widgets/inset_toggle.dart';
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
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existingBlock?.content ?? '');
    _controller.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  int get _charCount => _controller.text.length;

  int get _wordCount => _controller.text.trim().isEmpty
      ? 0
      : _controller.text.trim().split(RegExp(r'\s+')).length;

  int get _readingMinutes => (_charCount / 180).ceil().clamp(0, 999);

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

  void _insertLinePrefix(String prefix) {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final lineStart = start > 0 ? text.lastIndexOf('\n', start - 1) + 1 : 0;
    final newText = text.replaceRange(lineStart, lineStart, prefix);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + prefix.length),
    );
  }

  void _insertLink() {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final selected = text.substring(start, end);
    final label = selected.isEmpty ? 'نص الرابط' : selected;
    final replacement = '[$label](https://)';
    _controller.value = TextEditingValue(
      text: text.replaceRange(start, end, replacement),
      selection: TextSelection.collapsed(offset: start + replacement.length - 1),
    );
  }

  Widget _toolbar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.format_bold),
            tooltip: 'عريض',
            onPressed: () => _insertMarkdown('**'),
          ),
          IconButton(
            icon: const Icon(Icons.format_italic),
            tooltip: 'مائل',
            onPressed: () => _insertMarkdown('*'),
          ),
          IconButton(
            icon: const Icon(Icons.format_underlined),
            tooltip: 'تحته خط',
            onPressed: () => _insertMarkdown('<u>', closeTag: '</u>'),
          ),
          IconButton(
            icon: const Icon(Icons.format_strikethrough),
            tooltip: 'يتوسطه خط',
            onPressed: () => _insertMarkdown('~~'),
          ),
          const SizedBox(
            height: 24,
            child: VerticalDivider(width: 16),
          ),
          IconButton(
            icon: const Icon(Icons.title),
            tooltip: 'عنوان',
            onPressed: () => _insertLinePrefix('# '),
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted),
            tooltip: 'قائمة',
            onPressed: () => _insertLinePrefix('- '),
          ),
          IconButton(
            icon: const Icon(Icons.format_quote),
            tooltip: 'اقتباس',
            onPressed: () => _insertLinePrefix('> '),
          ),
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'كود',
            onPressed: () => _insertMarkdown('```\n', closeTag: '\n```'),
          ),
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'رابط',
            onPressed: _insertLink,
          ),
        ],
      ),
    );
  }

  Widget _editorField() {
    return TextFormField(
      controller: _controller,
      maxLines: null,
      minLines: null,
      expands: true,
      autofocus: true,
      textAlignVertical: TextAlignVertical.top,
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
    );
  }

  Widget _preview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.spacing8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: _controller.text.trim().isEmpty
            ? const Text(
                'لا يوجد نص للمعاينة',
                style: TextStyle(color: Colors.grey),
              )
            : MarkdownBody(data: _controller.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existingBlock = widget.existingBlock;
    final isWide =
        MediaQuery.of(context).size.width >= AppTokens.breakpointMobile;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
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
            _toolbar(),
            const SizedBox(height: 8),
            if (isWide)
              SizedBox(
                height: 320,
                child: Row(
                  children: [
                    Expanded(child: _editorField()),
                    const SizedBox(width: AppTokens.spacing8),
                    Expanded(child: _preview()),
                  ],
                ),
              )
            else ...[
              InsetToggle(
                value: _showPreview,
                onChanged: (val) => setState(() => _showPreview = val),
                labelLeft: 'تحرير',
                labelRight: 'معاينة',
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 240,
                child: _showPreview ? _preview() : _editorField(),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '$_wordCount كلمة · $_charCount حرف · ~$_readingMinutes د قراءة',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Spacer(),
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Text('يدعم لغة Markdown', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
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
      ),
    );
  }
}
