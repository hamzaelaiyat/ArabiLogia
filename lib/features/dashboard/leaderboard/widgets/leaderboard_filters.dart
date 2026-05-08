import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class LeaderboardFilters extends StatelessWidget {
  final int userGrade;
  final bool showOnlyMyGrade;
  final String selectedPeriod;
  final ValueChanged<bool> onGradeChanged;
  final ValueChanged<String> onPeriodChanged;

  const LeaderboardFilters({
    super.key,
    required this.userGrade,
    required this.showOnlyMyGrade,
    required this.selectedPeriod,
    required this.onGradeChanged,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.spacing8),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildGradeChip(context, 'صفي الدراسي', true),
                const SizedBox(width: 8),
                _buildGradeChip(context, 'كل الصفوف', false),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodChip(context, 'كل الوقت', 'all'),
                const SizedBox(width: 8),
                _buildPeriodChip(context, 'هذا الأسبوع', 'week'),
                const SizedBox(width: 8),
                _buildPeriodChip(context, 'هذا الشهر', 'month'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeChip(BuildContext context, String label, bool onlyMyGrade) {
    final isSelected = showOnlyMyGrade == onlyMyGrade;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onGradeChanged(onlyMyGrade);
        }
      },
      selectedColor: AppColors.chipSelectedColor(context),
    );
  }

  Widget _buildPeriodChip(BuildContext context, String label, String value) {
    final isSelected = selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected && selectedPeriod != value) {
          onPeriodChanged(value);
        }
      },
      selectedColor: AppColors.chipSelectedColor(context),
    );
  }
}
