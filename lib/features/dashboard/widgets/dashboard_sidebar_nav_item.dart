import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class DashboardSidebarNavItem extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback? onTap;

  const DashboardSidebarNavItem({
    super.key,
    required this.isSelected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing8,
        vertical: AppTokens.spacing2,
      ),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: AppTokens.radiusMdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTokens.radiusMdAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacing8,
              vertical: AppTokens.spacing6,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.mutedColor(context),
                  size: AppTokens.iconSizeMd,
                ),
                const SizedBox(width: AppTokens.spacing8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.foreground(context),
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
