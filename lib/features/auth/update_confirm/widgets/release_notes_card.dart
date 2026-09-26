import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/auth/update_confirm/screens/release_notes_detail_page.dart';

class ReleaseNotesCard extends StatelessWidget {
  final String releaseNotes;
  final String? version;

  const ReleaseNotesCard({super.key, required this.releaseNotes, this.version});

  String _getPreviewText(String fullNotes) {
    final lines = fullNotes.split('\n');
    if (lines.length <= 5 && fullNotes.length <= 200) {
      return fullNotes.trim();
    }
    final previewLines = <String>[];
    int charCount = 0;
    for (final line in lines) {
      previewLines.add(line);
      charCount += line.length;
      if (previewLines.length >= 4 || charCount >= 180) {
        break;
      }
    }
    return previewLines.join('\n').trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewText = _getPreviewText(releaseNotes);
    final hasMore = releaseNotes.trim().length > previewText.trim().length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.spacing16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ما الجديد:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: AppTokens.spacing12),
          MarkdownBody(
            data: previewText,
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
              h2: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
              h3: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              listBullet: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
          if (hasMore) ...[
            const SizedBox(height: AppTokens.spacing8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReleaseNotesDetailPage(
                      version: version ?? '',
                      releaseNotes: releaseNotes,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '..... عرض المزيد',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
