import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/core/services/potato_mode_service.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class PerformanceIndicator extends StatelessWidget {
  final bool showDetails;

  const PerformanceIndicator({super.key, this.showDetails = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<PotatoModeProvider>(
      builder: (context, potato, _) {
        if (!potato.isLoaded) {
          return const SizedBox.shrink();
        }

        final color = _getColor(potato.level);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.speed, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                potato.levelName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              if (showDetails && potato.deviceSpec != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${potato.deviceSpec!.ramGB}GB/${potato.deviceSpec!.cpuCores} cores',
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${potato.deviceSpec!.batteryPercent}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: potato.deviceSpec!.batteryPercent < 20
                        ? Colors.red
                        : color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getColor(PotatoLevel level) {
    switch (level) {
      case PotatoLevel.off:
        return Colors.green;
      case PotatoLevel.sweet:
        return Colors.orange;
      case PotatoLevel.tiny:
        return Colors.red;
    }
  }
}
