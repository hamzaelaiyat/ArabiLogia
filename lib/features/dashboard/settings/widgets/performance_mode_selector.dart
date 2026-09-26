import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/services/potato_mode_service.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';

Color _getPotatoColor(PotatoLevel level) {
  switch (level) {
    case PotatoLevel.off:
      return Colors.green;
    case PotatoLevel.sweet:
      return Colors.orange;
    case PotatoLevel.tiny:
      return Colors.red;
  }
}

class PerformanceModeSelector extends StatelessWidget {
  const PerformanceModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTokens.isMobile(context);
    return Card(
      key: TestKeys.settingsPerformanceMode,
      margin: isMobile
          ? EdgeInsets.zero
          : const EdgeInsets.all(AppTokens.spacing4),
      child: Consumer<PotatoModeProvider>(
        builder: (context, potato, child) {
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacing4,
                ),
                leading: Icon(
                  Icons.speed,
                  color: _getPotatoColor(potato.level),
                ),
                title: const Text('وضع الأداء'),
                subtitle: Text(
                  potato.levelName,
                  style: TextStyle(
                    color: _getPotatoColor(potato.level),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile
                      ? AppTokens.spacing4
                      : AppTokens.spacing8,
                  vertical: isMobile ? AppTokens.spacing2 : AppTokens.spacing6,
                ),
                child: isMobile
                    ? _buildDropdown(context, potato)
                    : Wrap(
                        spacing: AppTokens.spacing8,
                        runSpacing: AppTokens.spacing8,
                        children: PotatoLevel.values.map((level) {
                          final isSelected = potato.level == level;
                          final config = potato.getConfigForLevel(level);
                          return ChoiceChip(
                            label: Text(config.levelName),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                potato.setPotatoLevel(level);
                              }
                            },
                            selectedColor: _getPotatoColor(
                              level,
                            ).withValues(alpha: 0.3),
                            checkmarkColor: _getPotatoColor(level),
                            side: isSelected ? BorderSide.none : null,
                          );
                        }).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, PotatoModeProvider potato) {
    final current = potato.level;
    final color = _getPotatoColor(current);
    return Builder(
      builder: (innerContext) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppTokens.radiusMdAll,
            onTap: () => _openMenu(innerContext, potato),
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: AppTokens.radiusMdAll,
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacing2,
                  vertical: AppTokens.spacing4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        potato.getConfigForLevel(current).levelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTokens.fontFamilyBody,
                          fontSize: AppTokens.fontSizeMd,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: color, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMenu(
    BuildContext triggerContext,
    PotatoModeProvider potato,
  ) async {
    final box = triggerContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;
    final overlayBox =
        Overlay.of(triggerContext).context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;

    final origin = box.localToGlobal(Offset.zero);
    final overlayOrigin = overlayBox.localToGlobal(Offset.zero);
    final left = origin.dx - overlayOrigin.dx;
    final top = origin.dy - overlayOrigin.dy;
    final buttonWidth = box.size.width;

    final selected = await showMenu<PotatoLevel>(
      context: triggerContext,
      position: RelativeRect.fromLTRB(
        left,
        top + box.size.height,
        overlayBox.size.width - (left + box.size.width),
        overlayBox.size.height - (top + box.size.height),
      ),
      color: Theme.of(triggerContext).brightness == Brightness.dark
          ? AppColors.bgDark
          : Colors.white,
      items: [
        for (final level in PotatoLevel.values)
          PopupMenuItem<PotatoLevel>(
            value: level,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacing8,
              vertical: AppTokens.spacing2,
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                fontFamily: AppTokens.fontFamilyBody,
                fontSize: AppTokens.fontSizeMd,
                fontWeight: FontWeight.w700,
                color: _getPotatoColor(level),
              ),
              child: SizedBox(
                width: buttonWidth,
                child: Text(potato.getConfigForLevel(level).levelName),
              ),
            ),
          ),
      ],
    );
    if (selected != null) {
      potato.setPotatoLevel(selected);
    }
  }
}
