import 'package:flutter/material.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/auth/register/widgets/step_header.dart';
import 'package:arabilogia/features/auth/register/widgets/grade_selector.dart';
import 'package:arabilogia/features/auth/register/widgets/terms_agreement.dart';

class GradeStepForm extends StatelessWidget {
  final int? selectedGrade;
  final ValueChanged<int?> onGradeChanged;
  final bool termsAccepted;
  final ValueChanged<bool?> onTermsChanged;
  final Map<String, String> fieldErrors;

  const GradeStepForm({
    super.key,
    required this.selectedGrade,
    required this.onGradeChanged,
    required this.termsAccepted,
    required this.onTermsChanged,
    this.fieldErrors = const {},
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const StepHeader(
          title: 'المرحلة الدراسية',
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: AppTokens.spacing12),
        GradeSelector(
          key: TestKeys.registerGradeSelector,
          selectedGrade: selectedGrade,
          onChanged: onGradeChanged,
        ),
        const SizedBox(height: AppTokens.spacing12),
        TermsAgreement(
          value: termsAccepted,
          onChanged: onTermsChanged,
        ),
        if (fieldErrors.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              fieldErrors.values.join('\n'),
              style: TextStyle(color: colorScheme.error, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
