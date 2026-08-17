import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

Future<T?> showPaletteSlideUp<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.background(sheetContext),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.radius2xl),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: AppTokens.spacing6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      AppColors.mutedColor(sheetContext).withValues(alpha: 0.4),
                  borderRadius: AppTokens.radiusFullAll,
                ),
              ),
              Flexible(child: builder(sheetContext)),
            ],
          ),
        ),
      );
    },
  );
}
