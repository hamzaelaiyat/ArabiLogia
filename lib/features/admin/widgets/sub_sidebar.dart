
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';

class SubSidebar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onSave;
  final VoidCallback onPublish;
  final VoidCallback onExit;

  const SubSidebar({
    super.key,
    required this.activeIndex,
    required this.onIndexChanged,
    required this.onSave,
    required this.onPublish,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          _SidebarIcon(
            icon: Icons.arrow_back,
            isActive: false,
            onTap: onExit,
            tooltip: 'رجوع',
          ),
          const SizedBox(height: 16),
          _SidebarIcon(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            isActive: activeIndex == 0,
            onTap: () => onIndexChanged(0),
            tooltip: 'الإعدادات',
          ),
          const SizedBox(height: 16),
          _SidebarIcon(
            icon: Icons.edit_note_outlined,
            activeIcon: Icons.edit_note,
            isActive: activeIndex == 1,
            onTap: () => onIndexChanged(1),
            tooltip: 'الفقرات',
          ),
          const Spacer(),
          _SidebarIcon(
            icon: Icons.upload_outlined,
            isActive: false,
            onTap: onPublish,
            tooltip: 'نشر',
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          _SidebarIcon(
            icon: Icons.save_outlined,
            isActive: false,
            onTap: onSave,
            tooltip: 'حفظ مسودة',
          ),
        ],
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final bool isActive;
  final VoidCallback onTap;
  final String tooltip;
  final Color? color;

  const _SidebarIcon({
    required this.icon,
    this.activeIcon,
    required this.isActive,
    required this.onTap,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final potato = context.watch<PotatoModeProvider>();
    final sideDuration = potato.animationsEnabled
        ? AppTokens.durationFast
        : Duration.zero;
    final iconColor = color ?? (isActive 
        ? AppColors.primary 
        : AppColors.foreground(context).withValues(alpha: 0.6));

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: sideDuration,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive 
                ? AppColors.primary.withValues(alpha: 0.1) 
                : Colors.transparent,
            borderRadius: AppTokens.radiusMdAll,
          ),
          child: Icon(
            isActive ? (activeIcon ?? icon) : icon,
            color: iconColor,
            size: 24,
          ),
        ),
      ),
    );
  }
}
