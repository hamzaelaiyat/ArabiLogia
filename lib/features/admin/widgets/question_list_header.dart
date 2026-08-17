import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class QuestionListHeader extends StatelessWidget {
  final int questionCount;
  final bool isMobile;

  const QuestionListHeader({
    super.key,
    required this.questionCount,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? AppTokens.spacing12 : AppTokens.spacing32,
        isMobile ? AppTokens.spacing12 : AppTokens.spacing32,
        isMobile ? AppTokens.spacing12 : AppTokens.spacing32,
        isMobile ? AppTokens.spacing8 : AppTokens.spacing16,
      ),
      child: Row(
        children: [
          if (!isMobile) ...[
            const Icon(Icons.quiz_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
          ],
          Text(
            isMobile ? 'الأسئلة ($questionCount)' : 'بنك الأسئلة',
            style: TextStyle(
              fontSize: isMobile ? AppTokens.fontSizeLg : AppTokens.fontSize2xl,
              fontWeight: FontWeight.bold,
              fontFamily: AppTokens.fontFamilyDisplay,
              color: AppColors.foreground(context),
              letterSpacing: -0.5,
            ),
          ),
          if (!isMobile) ...[
            const Spacer(),
            Text(
              'إجمالي الأسئلة: $questionCount',
              style: TextStyle(
                color: AppColors.mutedColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
