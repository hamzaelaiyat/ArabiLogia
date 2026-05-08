import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class DashboardSidebarSecondaryNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const DashboardSidebarSecondaryNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing8,
        vertical: AppTokens.spacing2,
      ),
      child: Material(
        color: Colors.transparent,
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
                  icon,
                  color: AppColors.mutedColor(context),
                  size: AppTokens.iconSizeXs,
                ),
                const SizedBox(width: AppTokens.spacing8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.foreground(context),
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
