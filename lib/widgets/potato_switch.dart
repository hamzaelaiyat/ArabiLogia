import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';

class PotatoSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final double? width;
  final double? height;
  final String? label;

  const PotatoSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.width,
    this.height,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final potato = context.watch<PotatoModeProvider>();
    final switchDuration = potato.animationsEnabled
        ? AppTokens.durationFast
        : Duration.zero;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTrack = activeTrackColor ?? AppColors.primary;
    final inactiveTrack = inactiveTrackColor ?? (isDark ? Colors.grey.shade700 : Colors.grey.shade300);
    final thumbColor = activeColor ?? Colors.white;

    final w = width ?? 56.0;
    final h = height ?? 32.0;
    final thumbSize = h - 8;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onChanged != null ? () => onChanged!(!value) : null,
          child: AnimatedContainer(
            duration: switchDuration,
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: value ? activeTrack : inactiveTrack,
              borderRadius: BorderRadius.circular(h / 2),
              boxShadow: value ? [
                BoxShadow(
                  color: activeTrack.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: switchDuration,
                  left: value ? w - thumbSize - 4 : 4,
                  top: 4,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: thumbColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 6),
          Text(
            label!,
            style: TextStyle(
              fontSize: AppTokens.fontSizeSm,
              color: AppColors.mutedColor(context),
            ),
          ),
        ],
      ],
    );
  }
}

class PotatoSwitchListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? secondary;
  final Widget? title;
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
    this.title,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTrack = activeTrackColor ?? AppColors.primary;
    final inactiveTrack = inactiveTrackColor ?? (isDark ? Colors.grey.shade700 : Colors.grey.shade300);

    final leadingWidget = leading ?? secondary;

    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      borderRadius: AppTokens.radiusMdAll,
      child: Padding(
        padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (leadingWidget != null) ...[
              leadingWidget,
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: AppTokens.fontSizeMd,
                        fontWeight: FontWeight.w500,
                        color: AppColors.foreground(context),
                      ),
                      child: title!,
                    ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: AppTokens.fontSizeSm,
                        color: AppColors.mutedColor(context),
                      ),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            _InlineSwitch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: activeTrack,
              inactiveTrackColor: inactiveTrack,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeTrackColor;
  final Color inactiveTrackColor;

  const _InlineSwitch({
    required this.value,
    this.onChanged,
    required this.activeTrackColor,
    required this.inactiveTrackColor,
  });

  @override
  Widget build(BuildContext context) {
    final potato = context.watch<PotatoModeProvider>();
    final switchDuration = potato.animationsEnabled
        ? AppTokens.durationFast
        : Duration.zero;
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: switchDuration,
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          color: value ? activeTrackColor : inactiveTrackColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: switchDuration,
              left: value ? 26 : 4,
              top: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}