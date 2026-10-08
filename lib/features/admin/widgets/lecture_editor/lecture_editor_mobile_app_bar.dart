import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class LectureEditorMobileAppBar extends StatelessWidget {
  final String title;
  final bool isPublished;
  final VoidCallback onBack;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;

  const LectureEditorMobileAppBar({
    super.key,
    required this.title,
    this.isPublished = false,
    required this.onBack,
    required this.onSaveDraft,
    required this.onPublish,
    required this.onUnpublish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, color: AppColors.foreground(context)),
            tooltip: 'رجوع',
          ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title.isEmpty ? 'محاضرة جديدة' : title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isPublished
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPublished
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isPublished ? 'منشور' : 'مسودة',
                    style: TextStyle(
                      fontSize: 11,
                      color: isPublished
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.foreground(context)),
            tooltip: 'خيارات المحاضرة',
            onSelected: (value) {
              switch (value) {
                case 'save_draft':
                  onSaveDraft();
                  break;
                case 'publish':
                  onPublish();
                  break;
                case 'unpublish':
                  onUnpublish();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'save_draft',
                child: Row(
                  children: [
                    Icon(
                      Icons.save_outlined,
                      color: AppColors.foreground(context),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('حفظ كمسودة'),
                  ],
                ),
              ),
              if (!isPublished)
                const PopupMenuItem<String>(
                  value: 'publish',
                  child: Row(
                    children: [
                      Icon(
                        Icons.publish_rounded,
                        color: Colors.green,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text('نشر المحاضرة'),
                    ],
                  ),
                ),
              if (isPublished)
                const PopupMenuItem<String>(
                  value: 'unpublish',
                  child: Row(
                    children: [
                      Icon(
                        Icons.unpublished_outlined,
                        color: Colors.orange,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text('إلغاء النشر (تحويل كمسودة)'),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
