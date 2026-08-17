import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
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
            controller: _controller,
            keyboardType: TextInputType.url,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'أدخل رابط YouTube هنا...',
              labelText: 'اللينك هنا',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final url = _controller.text.trim();
              if (url.isNotEmpty) {
                final videoId = getVideoId(url);
                if (videoId.isEmpty && !url.contains('youtu')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الرجاء إدخال رابط يوتيوب صالح')),
                  );
                  return;
                }

                final block = LectureContentBlock(
                  id: existingBlock?.id ?? const Uuid().v4(),
                  type: BlockType.youtube,
                  content: url,
                  metadata: {
                    'title': 'مقطع مرئي للمحاضرة',
                    'duration': '56:59'
                  },
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
            child: const Text('إضافة لينك'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
