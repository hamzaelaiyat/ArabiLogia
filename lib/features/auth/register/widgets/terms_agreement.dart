import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/strings.dart';
import 'package:arabilogia/features/legal/widgets/legal_bottom_sheet.dart';

class TermsAgreement extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const TermsAgreement({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFEB8A00),
            side: BorderSide(color: AppColors.authLabelColor(context)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: AppTokens.spacing4),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'أوافق على ',
              style: TextStyle(
                color: AppColors.authHeaderColor(context),
                fontSize: AppTokens.fontSizeSm,
              ),
              children: [
                TextSpan(
                  text: AppStrings.terms,
                  style: const TextStyle(
                    color: Color(0xFFEB8A00),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => LegalBottomSheet.showTerms(context),
                ),
                const TextSpan(text: ' و '),
                TextSpan(
                  text: AppStrings.privacy,
                  style: const TextStyle(
                    color: Color(0xFFEB8A00),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => LegalBottomSheet.showPrivacy(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
