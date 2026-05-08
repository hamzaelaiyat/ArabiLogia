import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class MandatoryUpdateBanner extends StatelessWidget {
  const MandatoryUpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.spacing16),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.red),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'هذا التحديث إلزامي لإصلاح مشاكل أمنية مهمة',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
