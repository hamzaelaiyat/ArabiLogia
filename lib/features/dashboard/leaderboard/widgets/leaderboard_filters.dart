import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPillButton(
              context: context,
              label: 'صفي الدراسي',
              isSelected: showOnlyMyGrade,
              onTap: () => onGradeChanged(true),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildPillButton(
              context: context,
              label: 'كل الصفوف',
              isSelected: !showOnlyMyGrade,
              onTap: () => onGradeChanged(false),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    const activeBg = AppColors.blue;
    final inactiveBg = isDark ? AppColors.cardDark : const Color(0xFFE2E8F0);
    const activeTextColor = Colors.white;
    final inactiveTextColor = isDark
        ? const Color(0xFFCBD5E1)
        : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: isSelected ? activeTextColor : inactiveTextColor,
          ),
        ),
      ),
    );
  }
}
