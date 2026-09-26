import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_text_styles.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_markdown_style.dart';
import 'package:arabilogia/core/widgets/external_link_dialog.dart';
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

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleLinkTap(BuildContext context, String? href) async {
    if (href == null || href.trim().isEmpty) return;
    final url = href.trim();

    if (!isWebLink(url)) {
      _showMessage(context, 'نوع هذا الرابط غير مدعوم.');
      return;
    }

    final confirmed = await showExternalLinkWarningDialog(context, url);
    if (!confirmed || !context.mounted) return;

    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        return;
      }
    } catch (_) {
      // Fall through to the external application attempt below.
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'تعذّر فتح الرابط.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    await Clipboard.setData(ClipboardData(text: block.content));
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
              styleSheet: AppMarkdownStyle.build(context),
              onTapLink: (text, href, title) => _handleLinkTap(context, href),
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
