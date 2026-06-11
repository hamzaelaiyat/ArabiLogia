import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/features/auth/widgets/gradient_action_button.dart';
import 'package:arabilogia/features/auth/forgot_password/widgets/forgot_password_header.dart';
import 'package:arabilogia/features/auth/forgot_password/widgets/error_banner.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/strings.dart';
import 'package:arabilogia/providers/auth_provider.dart';

class ForgotPasswordOverlay extends StatefulWidget {
  const ForgotPasswordOverlay({super.key});

  static Future<void> show(BuildContext context) {
    final isMobile = AppTokens.isMobile(context);

    if (isMobile) {
      return showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).bottomSheetTheme.modalBackgroundColor,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        isScrollControlled: true,
        enableDrag: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        builder: (context) => const ForgotPasswordOverlay(),
      );
    }

    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: const ForgotPasswordOverlay(),
      ),
    );
  }

  @override
  State<ForgotPasswordOverlay> createState() => _ForgotPasswordOverlayState();
}

class _ForgotPasswordOverlayState extends State<ForgotPasswordOverlay> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitted = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(
      _emailController.text.trim(),
    );

    if (success && mounted) {
      setState(() => _isSubmitted = true);
    } else if (mounted) {
      setState(
        () => _errorMessage =
            'فشل في إرسال رابط إعادة التعيين. يرجى التحقق من البريد الإلكتروني.',
      );
    }
  }

  Future<void> _handleVerifyAndReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    final authProvider = context.read<AuthProvider>();

    try {
      // Step 1: Verify OTP
      final verified = await authProvider.verifyResetCode(
        _emailController.text.trim(),
        _otpController.text.trim(),
      );

      if (!verified) {
        setState(
          () => _errorMessage = 'رمز التفعيل غير صحيح. يرجى المحاولة مرة أخرى.',
        );
        return;
      }

      if (!mounted) return;

      // Step 2: Update Password
      final reset = await authProvider.updatePassword(_passwordController.text);

      if (!reset) {
        setState(
          () => _errorMessage =
              'فشل في تغيير كلمة المرور. يرجى المحاولة مرة أخرى.',
        );
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(
        () => _errorMessage =
            'حدث خطأ في الاتصال. يرجى التحقق من الاتصال بالانترنت والمحاولة مرة أخرى.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTokens.isMobile(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    if (isMobile) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: _buildContent(context, true),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: _buildContent(context, false),
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isMobile) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final solidInputDecoration = InputDecoration(
      filled: true,
      fillColor: isDark ? AppColors.secondaryDark : Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing16,
        vertical: AppTokens.spacing12,
      ),
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
      labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
      prefixIconColor: colorScheme.onSurface.withValues(alpha: 0.7),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTokens.spacing24,
        isMobile ? 0 : AppTokens.spacing12,
        AppTokens.spacing24,
        AppTokens.spacing32,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(32))
            : BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMobile) _buildDragHandle(context),
            if (!isMobile)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppColors.authHeaderColor(context),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ForgotPasswordHeader(isSubmitted: _isSubmitted),
            const SizedBox(height: AppTokens.spacing24),
            if (!_isSubmitted) ...[
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: AppColors.authTextColor(context)),
                decoration: solidInputDecoration.copyWith(
                  labelText: AppStrings.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال البريد الإلكتروني';
                  }
                  if (!value.contains('@')) {
                    return 'البريد الإلكتروني غير صالح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.spacing20),
              Consumer<AuthProvider>(
                builder: (context, auth, _) => GradientActionButton(
                  label: 'إرسال الرمز',
                  isLoading: auth.state.isLoading,
                  errorText: auth.state.error,
                  onPressed: _handleReset,
                ),
              ),
            ] else ...[
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppColors.authTextColor(context)),
                decoration: solidInputDecoration.copyWith(
                  labelText: 'رمز التفعيل',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'يرجى إدخال الرمز';
                  if (value.length < 6 || value.length > 8)
                    return 'الرمز يجب أن يكون 6 إلى 8 أرقام';
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.spacing16),
              ErrorBanner(message: _errorMessage),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: AppColors.authTextColor(context)),
                decoration: solidInputDecoration.copyWith(
                  labelText: 'كلمة المرور الجديدة',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.authLabelColor(context),
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'يرجى إدخال كلمة المرور';
                  if (value.length < 6) return 'يجب أن تكون 6 أحرف على الأقل';
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.spacing20),
              Consumer<AuthProvider>(
                builder: (context, auth, _) => GradientActionButton(
                  label: 'تغيير كلمة المرور',
                  isLoading: auth.state.isLoading,
                  errorText: auth.state.error,
                  onPressed: _handleVerifyAndReset,
                ),
              ),
              const SizedBox(height: AppTokens.spacing12),
              TextButton(
                onPressed: () => setState(() => _isSubmitted = false),
                child: Text(
                  'تغيير البريد الإلكتروني',
                  style: TextStyle(color: AppColors.authHeaderColor(context)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}
