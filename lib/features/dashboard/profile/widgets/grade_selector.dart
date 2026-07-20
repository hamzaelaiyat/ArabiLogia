import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class GradeSelector extends StatelessWidget {
  final int? selectedGrade;
  final bool isGradeLocked;
  final ValueChanged<int?> onSelect;

  const GradeSelector({
    super.key,
    required this.selectedGrade,
    required this.isGradeLocked,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final grades = [
      {'value': 10, 'label': 'الأولى باكالوريا'},
      {'value': 11, 'label': 'الثانية ثانوي'},
      {'value': 12, 'label': 'الثالثة ثانوي'},
    ];

    return Column(
      children: grades.map((g) {
        final isSelected = selectedGrade == g['value'];
        final isLocked = isGradeLocked && !isSelected;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.05)
                : AppColors.surface(context),
            borderRadius: AppTokens.radiusMdAll,
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: ListTile(
              title: Text(g['label'] as String),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : isLocked
                  ? const Icon(Icons.lock_outline, size: 20)
                  : null,
              onTap: isLocked
                  ? null
                  : () => onSelect(g['value'] as int),
              enabled: !isLocked,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class GradeChangeNotice extends StatelessWidget {
  const GradeChangeNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: AppTokens.radiusMdAll,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'تنبيه: يمكنك تغيير الصف الدراسي مرة واحدة كل 3 أيام فقط.',
              style: TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
