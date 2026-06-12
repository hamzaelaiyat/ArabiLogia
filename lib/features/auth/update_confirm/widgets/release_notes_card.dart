import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class ReleaseNotesCard extends StatelessWidget {
  final String releaseNotes;

  const ReleaseNotesCard({
    super.key,
    required this.releaseNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.new_releases_outlined,
                size: 20,
                color: Color(0xFFEB8A00),
              ),
              SizedBox(width: 8),
              Text(
                'ما الجديد؟',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacing12),
          Text(
            releaseNotes,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
