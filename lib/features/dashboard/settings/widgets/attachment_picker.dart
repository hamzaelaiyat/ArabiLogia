import 'dart:io';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:image_picker/image_picker.dart';

class AttachmentPicker extends StatefulWidget {
  final List<XFile> initialAttachments;
  final ValueChanged<List<XFile>> onAttachmentsChanged;
  final int maxAttachments;

  const AttachmentPicker({
    super.key,
    this.initialAttachments = const [],
    required this.onAttachmentsChanged,
    this.maxAttachments = 5,
  });

  @override
  State<AttachmentPicker> createState() => AttachmentPickerState();
}

class AttachmentPickerState extends State<AttachmentPicker> {
  late final ImagePicker _picker;
  late List<XFile> _attachments;

  @override
  void initState() {
    super.initState();
    _picker = ImagePicker();
    _attachments = List<XFile>.from(widget.initialAttachments);
  }

  Future<void> _pickAttachment() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
    );
    if (image != null && _attachments.length < widget.maxAttachments) {
      setState(() {
        _attachments.add(image);
      });
      widget.onAttachmentsChanged(List<XFile>.from(_attachments));
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
    widget.onAttachmentsChanged(List<XFile>.from(_attachments));
  }

  List<XFile> get attachments => List<XFile>.from(_attachments);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'مرفقات (لقطات شاشة أو فيديو)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: AppTokens.fontSizeMd,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${_attachments.length}/${widget.maxAttachments})',
              style: TextStyle(
                fontSize: AppTokens.fontSizeXs,
                color: AppColors.mutedColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._attachments.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: AppTokens.radiusMdAll,
                      color: Colors.black12,
                    ),
                    child: ClipRRect(
                      borderRadius: AppTokens.radiusMdAll,
                      child: Image.file(
                        File(file.path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image,
                          size: 32,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: GestureDetector(
                      onTap: () => _removeAttachment(index),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
            if (_attachments.length < widget.maxAttachments)
              GestureDetector(
                onTap: _pickAttachment,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: AppTokens.radiusMdAll,
                    border: Border.all(
                      color: AppColors.mutedColor(context),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
