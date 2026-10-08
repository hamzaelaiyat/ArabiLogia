import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

/// Opens a dropdown menu anchored directly below the widget whose [BuildContext]
/// is passed in, so the options never open on top of the selector regardless of
/// the current scroll position.
Future<T?> showAnchoredMenu<T>(
  BuildContext triggerContext,
  List<DropdownMenuItem<T>> items, {
  Color? color,
}) async {
  final box = triggerContext.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize || !box.attached) return null;
  final overlayBox =
      Overlay.of(triggerContext).context.findRenderObject() as RenderBox?;
  if (overlayBox == null) return null;

  final origin = box.localToGlobal(Offset.zero);
  final overlayOrigin = overlayBox.localToGlobal(Offset.zero);
  final left = origin.dx - overlayOrigin.dx;
  final top = origin.dy - overlayOrigin.dy;
  final buttonWidth = box.size.width;

  return showMenu<T>(
    context: triggerContext,
    position: RelativeRect.fromLTRB(
      left,
      top + box.size.height,
      overlayBox.size.width - (left + box.size.width),
      overlayBox.size.height - (top + box.size.height),
    ),
    items: [
      for (final item in items)
        PopupMenuItem<T>(
          value: item.value,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spacing8,
            vertical: AppTokens.spacing2,
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              fontFamily: AppTokens.fontFamilyBody,
              fontSize: AppTokens.fontSizeMd,
              fontWeight: FontWeight.w600,
            ),
            child: SizedBox(width: buttonWidth, child: item.child),
          ),
        ),
    ],
    color: color,
  );
}

/// A compact dropdown that opens its options below the field and renders like
/// the surrounding inputs, without the native dropdown's oversized text, gutters,
/// or per-option icons.
class AnchoredPickerField<T> extends StatelessWidget {
  const AnchoredPickerField({
    super.key,
    required this.value,
    required this.decoration,
    required this.items,
    required this.onChanged,
    this.labelFor,
  });

  final T? value;
  final InputDecoration decoration;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String Function(T value)? labelFor;

  String get _label {
    if (value == null) return '';
    if (labelFor != null) return labelFor!.call(value as T);
    for (final item in items) {
      if (item.value == value) {
        return _textFromChild(item.child);
      }
    }
    return '';
  }

  static String _textFromChild(Widget? child) {
    if (child is Text) return child.data ?? '';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final selected = await showAnchoredMenu<T>(
            context,
            items,
            color: isDark ? AppColors.bgDark : Colors.white,
          );
          if (selected != null) onChanged?.call(selected);
        },
        borderRadius: AppTokens.radiusMdAll,
        child: InputDecorator(
          decoration: decoration.copyWith(
            prefixIcon: null,
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: isDark ? AppColors.mutedDark : AppColors.textMuted,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          isEmpty: value == null,
          child: Text(
            _label,
            style: const TextStyle(
              fontFamily: AppTokens.fontFamilyBody,
              fontSize: AppTokens.fontSizeMd,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
