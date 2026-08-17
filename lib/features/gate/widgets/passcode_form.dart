import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PasscodeForm extends StatefulWidget {
  final int grade;
  final bool rotated;
  final Future<void> Function(String code) onSubmit;
  final VoidCallback? onCancel;

  const PasscodeForm({
    super.key,
    required this.grade,
    required this.onSubmit,
    this.rotated = false,
    this.onCancel,
  });

  @override
  State<PasscodeForm> createState() => _PasscodeFormState();
}

class _PasscodeFormState extends State<PasscodeForm> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final code = _controller.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'كلمة المرور قصيرة جداً');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(code);
      if (!mounted) return;
      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _humanError(e.toString());
        _busy = false;
        _focus.requestFocus();
      });
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
  }

  String _humanError(String raw) {
    if (raw.contains('غير صحيحة')) return 'كلمة المرور غير صحيحة';
    if (raw.contains('انتهت صلاحية')) return 'انتهت صلاحية كلمة المرور';
    if (raw.contains('تعليق المحاولات'))
      return 'تم تعليق المحاولات، حاول لاحقاً';
    if (raw.contains('غير مصرح')) return 'غير مصرح لك';
    return 'حدث خطأ، حاول مرة أخرى';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.rotated
                      ? 'تم تغيير كلمة المرور'
                      : 'أدخل كلمة مرور الصف',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'الصف ${_gradeLabel(widget.grade)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  focusNode: _focus,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.go,
                  enabled: !_busy,
                  inputFormatters: [LengthLimitingTextInputFormatter(32)],
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    border: const OutlineInputBorder(),
                    errorText: _error,
                    prefixIcon: const Icon(Icons.vpn_key),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('فتح'),
                ),
                if (widget.onCancel != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy ? null : widget.onCancel,
                    child: const Text('إلغاء'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _gradeLabel(int grade) {
    switch (grade) {
      case 1:
        return 'الأول الثانوي';
      case 2:
        return 'الثاني الثانوي';
      case 3:
        return 'الثالث الثانوي';
      default:
        return 'غير محدد';
    }
  }
}
