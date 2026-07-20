import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class DragHandle extends StatelessWidget {
  final Color? color;

  const DragHandle({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final handleColor =
        color ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: handleColor,
          borderRadius: AppTokens.radiusFullAll,
        ),
      ),
    );
  }
}
