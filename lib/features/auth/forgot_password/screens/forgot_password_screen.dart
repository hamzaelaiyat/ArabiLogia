import 'package:flutter/material.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/constants/strings.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/auth/forgot_password/widgets/error_banner.dart';
import 'package:arabilogia/features/auth/forgot_password/widgets/forgot_password_header.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:arabilogia/features/auth/widgets/auth_layout.dart';
import 'package:arabilogia/features/auth/widgets/auth_text_field.dart';
import 'package:arabilogia/features/auth/widgets/gradient_action_button.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
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
        context.go(AppRoutes.login);
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
    return AuthLayout(
      formChild: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacing8,
          vertical: AppTokens.spacing12,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo-removedbg.png',
                height: 90,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: AppTokens.spacing12),
              ForgotPasswordHeader(isSubmitted: _isSubmitted),
              const SizedBox(height: AppTokens.spacing24),
              if (!_isSubmitted) ...[
                AuthTextField(
                  controller: _emailController,
                  label: AppStrings.email,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
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
                AuthTextField(
                  controller: _otpController,
                  label: 'رمز التفعيل',
                  icon: Icons.vpn_key_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'يرجى إدخال الرمز';
                    if (value.length < 6 || value.length > 8) {
                      return 'الرمز يجب أن يكون 6 إلى 8 أرقام';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTokens.spacing16),
                ErrorBanner(message: _errorMessage),
                const SizedBox(height: AppTokens.spacing12),
                AuthTextField(
                  controller: _passwordController,
                  label: 'كلمة المرور الجديدة',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggleVisibility: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال كلمة المرور';
                    }
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
              const SizedBox(height: AppTokens.spacing20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'تذكرت كلمة المرور؟',
                    style: TextStyle(
                      color: AppColors.authHeaderColor(context),
                      fontSize: AppTokens.fontSizeMd,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text(
                      AppStrings.login,
                      style: TextStyle(
                        color: Color(0xFFEB8A00),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
