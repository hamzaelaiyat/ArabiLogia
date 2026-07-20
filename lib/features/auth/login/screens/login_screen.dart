import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/widgets/solid_container.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/strings.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/constants/test_keys.dart';

import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:arabilogia/features/dashboard/profile/providers/accounts_provider.dart';
import 'package:arabilogia/features/auth/forgot_password/screens/forgot_password_overlay.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/login_header.dart';
import '../widgets/login_button.dart';
import '../widgets/login_footer.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(email, password);

    if (success && mounted) {
      context.read<AccountsProvider>().saveCurrentSession(authProvider);
      setState(() => _showSuccess = true);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() => _showSuccess = false);
      final role = await authProvider.getUserRole();
      if (!mounted) return;
      if (role == 'admin' || role == 'teacher') {
        context.go(AppRoutes.teacherPanel);
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  Future<void> _handleResendVerification(AuthProvider authProvider) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    final success = await authProvider.resendOTP(email);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إعادة إرسال رمز التفعيل')),
      );
      // Optionally redirect to registration success view to enter OTP
      // But since we are on login, we might need a separate OTP overlay or just stay here.
      // For now, let's just stay and show the snackbar.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppTokens.isDesktop(context);
    final isMobile = AppTokens.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: TestKeys.loginScreen,
        body: Stack(
          children: [
            // Background Image/Solid Color
            Positioned.fill(
              child: isMobile
                  ? Container(
                      color: isDark
                          ? AppTokens.mobileDarkBackground
                          : AppTokens.mobileBackground,
                    )
                  : Image.asset(
                      isDark
                          ? 'assets/images/clouds-darkmode.png'
                          : 'assets/images/clouds-image.png',
                      fit: BoxFit.cover,
                    ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: isMobile
                    ? EdgeInsets.zero
                    : EdgeInsets.all(
                        isDesktop ? AppTokens.spacing16 : AppTokens.spacing8,
                      ),
                child: isDesktop
                    ? _buildDesktopLayout(context)
                    : _buildMobileLayout(context),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: _buildForm(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      child: _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final isMobile = AppTokens.isMobile(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final fieldErrors = auth.state.fieldErrors;

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
      suffixIconColor: colorScheme.onSurface.withValues(alpha: 0.7),
    );

    final content = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoginHeader(isMobile: isMobile),
          const SizedBox(height: AppTokens.spacing24),
          TextFormField(
            key: TestKeys.loginEmailField,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: colorScheme.onSurface),
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
          if (fieldErrors.containsKey('email')) ...[
            const SizedBox(height: 4),
            Text(
              fieldErrors['email']!,
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
              if (fieldErrors['email'] == 'يرجى تأكيد البريد الإلكتروني')
              TextButton(
                key: TestKeys.loginResendVerification,
                onPressed: () => _handleResendVerification(auth),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'إعادة إرسال رمز التفعيل',
                  style: TextStyle(
                    color: Color(0xFFEB8A00),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
          const SizedBox(height: AppTokens.spacing12),
          TextFormField(
            key: TestKeys.loginPasswordField,
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: solidInputDecoration.copyWith(
              labelText: AppStrings.password,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                key: TestKeys.loginPasswordVisibilityToggle,
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال كلمة المرور';
              }
              if (value.length < 6) {
                return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
              }
              return null;
            },
          ),
          if (fieldErrors.containsKey('password'))
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 16),
              child: Text(
                fieldErrors['password']!,
                style: TextStyle(color: colorScheme.error, fontSize: 12),
              ),
            ),
          const SizedBox(height: AppTokens.spacing8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: TestKeys.loginForgotPassword,
              onPressed: () => ForgotPasswordOverlay.show(context),
              child: Text(
                AppStrings.forgotPassword,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacing20),
          LoginButton(
            isLoading: auth.state.isLoading,
            showSuccess: _showSuccess,
            onPressed: _handleLogin,
          ),
          if (auth.state.error != null && fieldErrors.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.spacing8),
              child: Text(
                auth.state.error!,
                style: const TextStyle(
                  color: Color(0xFFD32F2F),
                  fontWeight: FontWeight.bold,
                  fontSize: AppTokens.fontSizeSm,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: AppTokens.spacing12),
          const LoginFooter(),
        ],
      ),
    );

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacing24,
          vertical: AppTokens.spacing32,
        ),
        child: content,
      );
    }

    return SolidContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing24,
        vertical: AppTokens.spacing32,
      ),
      child: content,
    );
  }
}
