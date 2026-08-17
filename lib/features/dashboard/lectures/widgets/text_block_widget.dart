import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_text_styles.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/lectures/models/lecture.dart';

class TextBlockWidget extends StatelessWidget {
  final LectureContentBlock block;
  final bool isCompleted;
  final VoidCallback onToggleCompletion;

  const TextBlockWidget({
    super.key,
    required this.block,
    required this.isCompleted,
    required this.onToggleCompletion,
  });

  int get _readingMinutes => (block.content.length / 180).ceil().clamp(1, 999);

  @override
  Widget build(BuildContext context) {
    final foreground = AppColors.foreground(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing16),
      shape: RoundedRectangleBorder(borderRadius: AppTokens.radiusLgAll),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: AppTokens.iconSizeXs,
                  color: AppColors.mutedColor(context),
                ),
                const SizedBox(width: AppTokens.spacing2),
                Text(
                  '~$_readingMinutes د قراءة',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedColor(context),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'نسخ النص',
                  icon: Icon(
                    Icons.copy_outlined,
                    size: AppTokens.iconSizeXs,
                    color: AppColors.mutedColor(context),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: block.content),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ النص')),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacing4),
            MarkdownBody(
              data: block.content,
              styleSheet:
                  MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: AppTextStyles.bodyLg.copyWith(color: foreground),
                h1: AppTextStyles.headingLg.copyWith(color: foreground),
                h2: AppTextStyles.headingMd.copyWith(color: foreground),
                h3: AppTextStyles.headingSm.copyWith(color: foreground),
                listBullet: AppTextStyles.bodyLg.copyWith(color: foreground),
                blockquote: AppTextStyles.bodyLg.copyWith(
                  color: AppColors.mutedColor(context),
                  fontStyle: FontStyle.italic,
                ),
                blockquoteDecoration: BoxDecoration(
                  color: AppColors.surface(context),
                  border: const Border(
                    right: BorderSide(color: AppColors.primary, width: 3),
                  ),
                ),
                code: AppTextStyles.bodyMd.copyWith(
                  fontFamily: 'monospace',
                  backgroundColor: AppColors.surface(context),
                ),
                codeblockDecoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: AppTokens.radiusSmAll,
                ),
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onToggleCompletion,
                  icon: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isCompleted ? Colors.green : Colors.grey,
                  ),
                  label: Text(
                    isCompleted ? 'تم القراءة' : 'تحديد كمقروء',
                    style: TextStyle(
                      color: isCompleted ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
