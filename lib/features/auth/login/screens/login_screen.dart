import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/auth/widgets/glass_container.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/strings.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/features/auth/widgets/theme_toggle_button.dart';
import 'package:arabilogia/features/auth/forgot_password/screens/forgot_password_overlay.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
      // After login, get the user role to determine redirect target
      final role = await authProvider.getUserRole();
      if (role == 'admin' || role == 'teacher') {
        context.go(AppRoutes.teacherPanel);
      } else {
        context.go('/home');
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
            const Positioned(
              top: 0,
              left: 0,
              child: SafeArea(child: ThemeToggleButton()),
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
    final cloudyInputDecoration = InputDecoration(
      filled: true,
      fillColor: AppColors.glassBackgroundColor(context),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing16,
        vertical: AppTokens.spacing12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        borderSide: BorderSide(color: AppColors.glassBorderColor(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        borderSide: BorderSide(color: AppColors.glassBorderColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      labelStyle: TextStyle(color: AppColors.authLabelColor(context)),
      prefixIconColor: AppColors.authLabelColor(context),
      suffixIconColor: AppColors.authLabelColor(context),
    );

    final content = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo-removedbg.png',
            height: isMobile ? 80 : 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppTokens.spacing12),
          Text(
            AppStrings.login,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEB8A00),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTokens.spacing24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: AppColors.authTextColor(context)),
            decoration: cloudyInputDecoration.copyWith(
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
          const SizedBox(height: AppTokens.spacing12),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: AppColors.authTextColor(context)),
            decoration: cloudyInputDecoration.copyWith(
              labelText: AppStrings.password,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
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
          const SizedBox(height: AppTokens.spacing8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => ForgotPasswordOverlay.show(context),
              child: Text(
                AppStrings.forgotPassword,
                style: TextStyle(
                  color: AppColors.authSecondaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacing20),
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: AppTokens.buttonHeightMd,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEB8A00), Color(0xFFFFA726)],
                      ),
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEB8A00).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: auth.state.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusFull,
                          ),
                        ),
                      ),
                      child: auth.state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              AppStrings.login,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (auth.state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTokens.spacing8),
                      child: Column(
                        children: [
                          Text(
                            auth.state.error!,
                            style: const TextStyle(
                              color: Color(0xFFD32F2F),
                              fontWeight: FontWeight.bold,
                              fontSize: AppTokens.fontSizeSm,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (auth.state.error ==
                              'يرجى تأكيد البريد الإلكتروني')
                            TextButton(
                              onPressed: () => _handleResendVerification(auth),
                              child: const Text(
                                'إعادة إرسال رمز التفعيل',
                                style: TextStyle(
                                  color: Color(0xFFEB8A00),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTokens.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.noAccount,
                style: TextStyle(
                  color: AppColors.authHeaderColor(context),
                  fontSize: AppTokens.fontSizeMd,
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.register),
                child: const Text(
                  AppStrings.register,
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

    return GlassContainer(
      isMobile: isMobile,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing24,
        vertical: AppTokens.spacing32,
      ),
      child: content,
    );
  }
}
