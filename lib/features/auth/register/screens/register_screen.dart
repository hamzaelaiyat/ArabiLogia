import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/widgets/solid_container.dart';
import 'package:arabilogia/features/auth/register/widgets/account_step_form.dart';
import 'package:arabilogia/features/auth/register/widgets/profile_step_form.dart';
import 'package:arabilogia/features/auth/register/widgets/grade_step_form.dart';
import 'package:arabilogia/features/auth/register/widgets/email_verification_card.dart';
import 'package:arabilogia/features/auth/register/widgets/step_progress_indicator.dart';
import 'package:arabilogia/features/auth/register/widgets/registration_footer.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/strings.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/features/auth/widgets/theme_toggle_button.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSuccess = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();

  int? _selectedGrade;
  bool _termsAccepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep = 1);
      }
    } else if (_currentStep == 1) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep = 2);
      }
    } else if (_currentStep == 2) {
      if (_formKey.currentState!.validate()) {
        if (_selectedGrade != null) {
          _handleRegister();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يرجى اختيار الصف الدراسي')),
          );
        }
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _handleRegister() async {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى الموافقة على الشروط والأحكام')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      _emailController.text.trim(),
      _passwordController.text,
      _fullNameController.text.trim(),
      _usernameController.text.trim(),
      _selectedGrade!,
    );

    if (success && mounted) {
      setState(() => _isSuccess = true);
    }
  }

  Future<void> _handleVerifyEmail(String otp) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyEmail(
      _emailController.text.trim(),
      otp,
    );

    if (success && mounted) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleResendCode() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resendOTP(_emailController.text.trim());

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إعادة إرسال رمز التفعيل')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppTokens.isDesktop(context);
    final isMobile = AppTokens.isMobile(context);
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : 500,
                  ),
                  child: _isSuccess
                      ? EmailVerificationCard(
                          email: _emailController.text.trim(),
                          isLoading: authProvider.state.isLoading,
                          error: authProvider.state.error,
                          onVerify: _handleVerifyEmail,
                          onResend: _handleResendCode,
                          onBackToLogin: () => context.go(AppRoutes.login),
                        )
                      : _buildFormCard(context, authProvider),
                ),
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

  Widget _buildFormCard(BuildContext context, AuthProvider authProvider) {
    final isMobile = AppTokens.isMobile(context);

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
            AppStrings.register,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFFEB8A00),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTokens.spacing24),
          StepProgressIndicator(currentStep: _currentStep, totalSteps: 3),
          const SizedBox(height: AppTokens.spacing24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_currentStep),
              child: _buildStepContent(context),
            ),
          ),
          const SizedBox(height: AppTokens.spacing24),
          RegistrationFooter(
            onNext: _nextStep,
            onBack: _previousStep,
            isFirstStep: _currentStep == 0,
            isLastStep: _currentStep == 2,
            isLoading: authProvider.state.isLoading,
          ),
          if (authProvider.state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.spacing4),
              child: Text(
                authProvider.state.error!,
                style: const TextStyle(
                  color: Color(0xFFD32F2F),
                  fontWeight: FontWeight.bold,
                  fontSize: AppTokens.fontSizeSm,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: AppTokens.spacing20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'لديك حساب بالفعل؟',
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

  Widget _buildStepContent(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return AccountStepForm(
          emailController: _emailController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          obscurePassword: _obscurePassword,
          obscureConfirmPassword: _obscureConfirmPassword,
          onTogglePasswordVisibility: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onToggleConfirmPasswordVisibility: () =>
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        );
      case 1:
        return ProfileStepForm(
          fullNameController: _fullNameController,
          usernameController: _usernameController,
        );
      case 2:
        return GradeStepForm(
          selectedGrade: _selectedGrade,
          onGradeChanged: (val) => setState(() => _selectedGrade = val),
          termsAccepted: _termsAccepted,
          onTermsChanged: (val) =>
              setState(() => _termsAccepted = val ?? false),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
