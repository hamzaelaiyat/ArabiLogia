import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class UpdateHeader extends StatelessWidget {
  final String version;
  final int fileSize;

  const UpdateHeader({
    super.key,
    required this.version,
    required this.fileSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo-removedbg.png',
          height: 80,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: AppTokens.spacing24),
        Text(
          'إصدار جديد: $version',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTokens.spacing8),
        Text(
          'حجم التحديث: ${_formatFileSize(fileSize)}',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}
