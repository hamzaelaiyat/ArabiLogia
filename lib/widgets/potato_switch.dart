import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class PotatoSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? activeTrackColor;
  final Color? inactiveThumbColor;
  final Color? inactiveTrackColor;
  final double? thumbSize;

  const PotatoSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.thumbSize,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PotatoModeProvider>(
      builder: (context, potato, _) {
        if (potato.animationsEnabled) {
          return Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
            activeTrackColor: activeTrackColor,
            inactiveThumbColor: inactiveThumbColor,
            inactiveTrackColor: inactiveTrackColor,
          );
        }

        return _buildInstantSwitch(context);
      },
    );
  }

  Widget _buildInstantSwitch(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final trackColor = value
        ? (activeTrackColor ?? AppColors.primary)
        : (inactiveTrackColor ??
              (isDark ? Colors.grey.shade800 : Colors.grey.shade300));

    final thumbColor = value
        ? (activeColor ?? Colors.white)
        : (inactiveThumbColor ??
              (isDark ? Colors.grey.shade400 : Colors.grey.shade500));

    final size = thumbSize ?? 24.0;
    final trackWidth = size * 1.8;
    final trackHeight = size * 1.1;

    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: Container(
        width: trackWidth,
        height: trackHeight,
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(trackHeight / 2),
        ),
        child: AnimatedAlign(
          duration: Duration.zero,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.all(size * 0.1),
            width: size - (size * 0.2),
            height: size - (size * 0.2),
            decoration: BoxDecoration(
              color: thumbColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class PotatoSwitchListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? secondary;
  final Widget title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool? dense;
  final EdgeInsetsGeometry? contentPadding;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;

  const PotatoSwitchListTile({
    super.key,
    this.leading,
    this.secondary,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.dense,
    this.contentPadding,
    this.activeTrackColor,
    this.inactiveTrackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PotatoModeProvider>(
      builder: (context, potato, _) {
        if (potato.animationsEnabled) {
          return SwitchListTile(
            secondary: leading ?? secondary,
            title: title,
            subtitle: subtitle,
            value: value,
            onChanged: onChanged,
            dense: dense,
            contentPadding: contentPadding,
            activeTrackColor: activeTrackColor,
            inactiveTrackColor: inactiveTrackColor,
          );
        }

        return ListTile(
          leading: PotatoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: activeTrackColor,
            inactiveTrackColor: inactiveTrackColor,
          ),
          title: title,
          subtitle: subtitle,
          dense: dense,
          contentPadding: contentPadding,
          onTap: onChanged != null ? () => onChanged!(!value) : null,
        );
      },
    );
  }
}
