import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/strings.dart';

class GradeSelector extends StatelessWidget {
  final int? selectedGrade;
  final ValueChanged<int?> onChanged;

  const GradeSelector({
    super.key,
    required this.selectedGrade,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> grades = [
      {
        'id': 10,
        'name': AppStrings.grade10,
        'icon': Icons.looks_one_outlined,
      },
      {
        'id': 11,
        'name': AppStrings.grade11,
        'icon': Icons.looks_two_outlined,
      },
      {
        'id': 12,
        'name': AppStrings.grade12,
        'icon': Icons.looks_3_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            right: AppTokens.spacing4,
            bottom: AppTokens.spacing4,
          ),
          child: Text(
            AppStrings.selectGrade,
            style: TextStyle(
              color: AppColors.authHeaderColor(context),
              fontWeight: FontWeight.bold,
              fontSize: AppTokens.fontSizeMd,
            ),
          ),
        ),
        const SizedBox(height: AppTokens.spacing4),
        ...grades.map((grade) {
          final isSelected = selectedGrade == grade['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.spacing4),
            child: InkWell(
              onTap: () => onChanged(grade['id']),
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacing8,
                  vertical: AppTokens.spacing6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEB8A00).withValues(alpha: 0.1)
                      : AppColors.glassBackgroundColor(context),
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFEB8A00)
                        : AppColors.glassBorderColor(context),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      grade['icon'] as IconData,
                      color: isSelected
                          ? const Color(0xFFEB8A00)
                          : AppColors.authLabelColor(context),
                    ),
                    const SizedBox(width: AppTokens.spacing6),
                    Text(
                      grade['name'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFEB8A00)
                            : AppColors.authTextColor(context),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: AppTokens.fontSizeMd,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFFEB8A00),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
