import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/services/potato_mode_service.dart';
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
    return Card(
      child: Consumer<PotatoModeProvider>(
        builder: (context, potato, child) {
          return Column(
            children: [
              ListTile(
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
                padding: const EdgeInsets.all(AppTokens.spacing8),
                child: Wrap(
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
}
