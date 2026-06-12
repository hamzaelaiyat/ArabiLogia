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
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFEB8A00).withAlpha(25),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.system_update,
            size: 50,
            color: Color(0xFFEB8A00),
          ),
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
