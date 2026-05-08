import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class StepHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const StepHeader({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFEB8A00), size: 18),
        const SizedBox(width: AppTokens.spacing4),
        Text(
          title,
          style: TextStyle(
            color: AppColors.authHeaderColor(context),
            fontWeight: FontWeight.bold,
            fontSize: AppTokens.fontSizeLg,
          ),
        ),
      ],
    );
  }
}
