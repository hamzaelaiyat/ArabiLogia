import 'package:flutter/material.dart';

class UpdateActionButtons extends StatelessWidget {
  final VoidCallback onUpdateNow;
  final VoidCallback onRemindLater;
  final VoidCallback onSkip;

  const UpdateActionButtons({
    super.key,
    required this.onUpdateNow,
    required this.onRemindLater,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onUpdateNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEB8A00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'تحديث الآن',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onRemindLater,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFEB8A00)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'ذكرني لاحقاً',
              style: TextStyle(color: Color(0xFFEB8A00), fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onSkip,
          child: Text(
            'تخطي هذه النسخة',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
      ],
    );
  }
}
