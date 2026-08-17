import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/utils/video_utils.dart';
import 'package:arabilogia/features/dashboard/lectures/models/lecture.dart';

class YoutubeLinkEditorSheet extends StatefulWidget {
  final LectureContentBlock? existingBlock;
  final int? index;
  final void Function(LectureContentBlock, int?) onSave;

  const YoutubeLinkEditorSheet({
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
      builder: (ctx) => YoutubeLinkEditorSheet(
        existingBlock: existingBlock,
        index: index,
        onSave: onSave,
      ),
    );
  }

  @override
  State<YoutubeLinkEditorSheet> createState() => _YoutubeLinkEditorSheetState();
}

class _YoutubeLinkEditorSheetState extends State<YoutubeLinkEditorSheet> {
  late final TextEditingController _urlController;
  late final TextEditingController _titleController;
  late final TextEditingController _durationController;
  String _videoId = '';

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.existingBlock?.content ?? '');
    _titleController = TextEditingController(
      text: widget.existingBlock?.metadata?['title']?.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: widget.existingBlock?.metadata?['duration']?.toString() ?? '',
    );
    _videoId = getVideoId(_urlController.text.trim());
    _urlController.addListener(_onUrlChanged);
  }

  void _onUrlChanged() {
    setState(() => _videoId = getVideoId(_urlController.text.trim()));
  }

  bool get _hasError =>
      _urlController.text.trim().isNotEmpty && _videoId.isEmpty;

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint, {String? label, String? errorText}) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      errorText: errorText,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  existingBlock != null ? 'تعديل رابط الفيديو' : 'إضافة رابط يوتيوب',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            TextFormField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              autofocus: true,
              decoration: _decoration(
                'أدخل رابط YouTube هنا...',
                label: 'رابط الفيديو',
                errorText: _hasError ? 'الرجاء إدخال رابط يوتيوب صالح' : null,
              ),
            ),
            if (_videoId.isNotEmpty) ...[
              const SizedBox(height: AppTokens.spacing8),
              ClipRRect(
                borderRadius: AppTokens.radiusMdAll,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    'https://img.youtube.com/vi/$_videoId/hqdefault.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppTokens.spacing8),
            TextFormField(
              controller: _titleController,
              decoration: _decoration(
                'مثال: شرح الدرس الأول',
                label: 'عنوان الفيديو',
              ),
            ),
            const SizedBox(height: AppTokens.spacing8),
            TextFormField(
              controller: _durationController,
              decoration: _decoration(
                'مثال: 12:30',
                label: 'المدة (اختياري)',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final url = _urlController.text.trim();
                if (url.isEmpty || _videoId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الرجاء إدخال رابط يوتيوب صالح')),
                  );
                  return;
                }

                final title = _titleController.text.trim();
                final block = LectureContentBlock(
                  id: existingBlock?.id ?? const Uuid().v4(),
                  type: BlockType.youtube,
                  content: url,
                  metadata: {
                    ...?existingBlock?.metadata,
                    'title': title.isEmpty ? 'مقطع مرئي للمحاضرة' : title,
                    'duration': _durationController.text.trim(),
                  },
                );
                widget.onSave(block, widget.index);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(existingBlock != null ? 'تحديث الفيديو' : 'إضافة الفيديو'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
