import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Key? fieldKey;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.obscureText = true,
    this.onToggleVisibility,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.fieldKey,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _isHoveredOverField = false;
  bool _isHoveredOverEye = false;
  bool _isEyePressed = false;
  late bool _toggleObscure;

  @override
  void initState() {
    super.initState();
    _toggleObscure = widget.obscureText;
  }

  @override
  void didUpdateWidget(AuthTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.obscureText != oldWidget.obscureText) {
      _toggleObscure = widget.obscureText;
    }
  }

  bool get _shouldObscure {
    if (!widget.isPassword) return widget.obscureText;
    // Reveal password text when hovering or pressing down on the eye button
    if (_isHoveredOverEye || _isEyePressed) return false;
    return _toggleObscure;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    Widget? suffixWidget;

    if (widget.isPassword) {
      final isEyeVisible =
          _isHoveredOverField || _isHoveredOverEye || _isEyePressed || !_toggleObscure;

      suffixWidget = MouseRegion(
        onEnter: (_) => setState(() => _isHoveredOverEye = true),
        onExit: (_) => setState(() => _isHoveredOverEye = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isEyePressed = true),
          onTapUp: (_) => setState(() => _isEyePressed = false),
          onTapCancel: () => setState(() => _isEyePressed = false),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isEyeVisible ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !isEyeVisible,
              child: IconButton(
                key: widget.fieldKey != null
                    ? Key('${widget.fieldKey.toString()}_eye_btn')
                    : null,
                icon: Icon(
                  _shouldObscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                onPressed: () {
                  setState(() {
                    _toggleObscure = !_toggleObscure;
                  });
                  widget.onToggleVisibility?.call();
                },
              ),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveredOverField = true),
      onExit: (_) => setState(() => _isHoveredOverField = false),
      child: TextFormField(
        key: widget.fieldKey,
        controller: widget.controller,
        obscureText: _shouldObscure,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.icon, color: colorScheme.onSurface.withValues(alpha: 0.7)),
          suffixIcon: suffixWidget,
          filled: true,
          fillColor: isDark ? AppColors.secondaryDark : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spacing16,
            vertical: AppTokens.spacing12,
          ),
          labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            borderSide: BorderSide(color: colorScheme.error, width: 2),
          ),
        ),
        validator: widget.validator,
      ),
    );
  }
}
