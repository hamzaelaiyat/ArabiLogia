import 'package:flutter/material.dart';

class ActionButtonsWidget extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onRetakePressed;

  const ActionButtonsWidget({
    super.key,
    required this.onHomePressed,
    required this.onRetakePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onHomePressed,
            child: const Text('العودة للرئيسية'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: onRetakePressed,
            child: const Text('إعادة الاختبار'),
          ),
        ),
      ],
    );
  }
}
