import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';

class InsetToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String labelLeft;
  final String labelRight;

  const InsetToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelLeft = 'تعديل',
    this.labelRight = 'إعدادات',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final potato = context.watch<PotatoModeProvider>();
    final animate = potato.animationsEnabled;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111315) : const Color(0xFFE5E9EC),
        borderRadius: AppTokens.radiusFullAll,
        boxShadow: potato.shadowsEnabled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 4,
                  spreadRadius: -1,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / 2;
          return Stack(
            children: [
              if (animate)
                AnimatedAlign(
                  duration: AppTokens.durationFast,
                  curve: AppTokens.curveInOut,
                  alignment: value ? Alignment.centerLeft : Alignment.centerRight,
                  child: _slider(width, isDark, potato.shadowsEnabled),
                )
              else
                Align(
                  alignment: value ? Alignment.centerLeft : Alignment.centerRight,
                  child: _slider(width, isDark, false),
                ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(false),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          labelLeft,
                          style: TextStyle(
                            fontSize: AppTokens.fontSizeMd,
                            fontWeight: !value ? FontWeight.bold : FontWeight.w500,
                            color: !value
                                ? AppColors.foreground(context)
                                : AppColors.mutedColor(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(true),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          labelRight,
                          style: TextStyle(
                            fontSize: AppTokens.fontSizeMd,
                            fontWeight: value ? FontWeight.bold : FontWeight.w500,
                            color: value
                                ? AppColors.foreground(context)
                                : AppColors.mutedColor(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _slider(double width, bool isDark, bool shadows) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2E30) : Colors.white,
        borderRadius: AppTokens.radiusFullAll,
        boxShadow: shadows
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }
}
