import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';

class ExamResultsFilter extends StatelessWidget {
  final int selectedGrade;
  final ValueChanged<int> onGradeChanged;

  const ExamResultsFilter({
    super.key,
    required this.selectedGrade,
    required this.onGradeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'تصفية حسب الصف:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  grade: 0,
                  label: 'الكل',
                  isSelected: selectedGrade == 0,
                  onTap: () => onGradeChanged(0),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  grade: 1,
                  label: 'أول ثانوي',
                  isSelected: selectedGrade == 1,
                  onTap: () => onGradeChanged(1),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  grade: 2,
                  label: 'ثاني ثانوي',
                  isSelected: selectedGrade == 2,
                  onTap: () => onGradeChanged(2),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  grade: 3,
                  label: 'ثالث ثانوي',
                  isSelected: selectedGrade == 3,
                  onTap: () => onGradeChanged(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final int grade;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.grade,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final potato = context.watch<PotatoModeProvider>();
    final filterDuration = potato.animationsEnabled
        ? AppTokens.durationSm
        : Duration.zero;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: filterDuration,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}