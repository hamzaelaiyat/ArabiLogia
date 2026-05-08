import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class DownloadProgressSection extends StatelessWidget {
  final double progress;
  final String status;

  const DownloadProgressSection({
    super.key,
    required this.progress,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(value: progress),
        const SizedBox(height: AppTokens.spacing12),
        Text(status, style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: AppTokens.spacing24),
      ],
    );
  }
}
