import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/auth/register/widgets/step_header.dart';
import 'package:arabilogia/features/auth/register/widgets/grade_selector.dart';
import 'package:arabilogia/features/auth/register/widgets/terms_agreement.dart';

class GradeStepForm extends StatelessWidget {
  final int? selectedGrade;
  final ValueChanged<int?> onGradeChanged;
  final bool termsAccepted;
  final ValueChanged<bool?> onTermsChanged;

  const GradeStepForm({
    super.key,
    required this.selectedGrade,
    required this.onGradeChanged,
    required this.termsAccepted,
    required this.onTermsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const StepHeader(
          title: 'المرحلة الدراسية',
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: AppTokens.spacing12),
        GradeSelector(
          selectedGrade: selectedGrade,
          onChanged: onGradeChanged,
        ),
        const SizedBox(height: AppTokens.spacing12),
        TermsAgreement(
          value: termsAccepted,
          onChanged: onTermsChanged,
        ),
      ],
    );
  }
}
