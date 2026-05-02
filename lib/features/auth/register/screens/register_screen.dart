import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/auth/widgets/glass_container.dart';
import 'package:arabilogia/features/auth/register/widgets/grade_selector.dart';
import 'package:arabilogia/features/auth/register/widgets/terms_agreement.dart';
import 'package:arabilogia/features/auth/register/widgets/step_progress_indicator.dart';
import 'package:arabilogia/features/auth/register/widgets/registration_footer.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/strings.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/features/auth/widgets/theme_toggle_button.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

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
  final _otpController = TextEditingController();

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
    _otpController.dispose();
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

  Future<void> _handleVerifyEmail() async {
    final otp = _normalizeOtp(_otpController.text);
    if (otp.length < 6 || otp.length > 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رمز تفعيل صحيح (6 إلى 8 أرقام)'),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyEmail(
      _emailController.text.trim(),
      otp,
    );

    if (success && mounted) {
      context.go(AppRoutes.home);
    }
  }

  String _normalizeOtp(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final codePoint = rune;
      // Convert Arabic-Indic and Eastern Arabic-Indic numerals to ASCII digits.
      if (codePoint >= 0x0660 && codePoint <= 0x0669) {
        buffer.writeCharCode(0x30 + (codePoint - 0x0660));
      } else if (codePoint >= 0x06F0 && codePoint <= 0x06F9) {
        buffer.writeCharCode(0x30 + (codePoint - 0x06F0));
      } else if (RegExp(r'[0-9]').hasMatch(char)) {
        buffer.write(char);
      }
    }
    return buffer.toString();
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
          automaticallyImplyLeading: false, // Prevents default back button
        ),
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : 500,
                  ),
                  child: _isSuccess
                      ? _buildSuccessCard(context)
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

  Widget _buildSuccessCard(BuildContext context) {
    final isMobile = AppTokens.isMobile(context);
    final authProvider = context.watch<AuthProvider>();

    return GlassContainer(
      isMobile: isMobile,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing24,
        vertical: AppTokens.spacing32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            size: 60,
            color: Color(0xFFEB8A00),
          ),
          const SizedBox(height: AppTokens.spacing8),
          const Text(
            'تأكيد الحساب',
            style: TextStyle(
              color: Color(0xFFEB8A00),
              fontWeight: FontWeight.bold,
              fontSize: AppTokens.fontSize2xl,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTokens.spacing12),
          Text(
            'لقد أرسلنا رمز تفعيل مكون من 6 إلى 8 أرقام إلى بريدك الإلكتروني:',
            style: TextStyle(
              color: AppColors.authHeaderColor(context),
              fontSize: AppTokens.fontSizeMd,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            _emailController.text,
            style: const TextStyle(
              color: Color(0xFFEB8A00),
              fontWeight: FontWeight.bold,
              fontSize: AppTokens.fontSizeMd,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTokens.spacing24),
          _buildTextField(
            controller: _otpController,
            label: 'رمز التفعيل',
            icon: Icons.vpn_key_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'يرجى إدخال الرمز';
              final normalized = _normalizeOtp(value);
              if (normalized.length < 6 || normalized.length > 8) {
                return 'يجب أن يكون الرمز من 6 إلى 8 أرقام';
              }
              return null;
            },
          ),
          if (authProvider.state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.spacing12),
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
          const SizedBox(height: AppTokens.spacing24),
          SizedBox(
            width: double.infinity,
            height: AppTokens.isMobile(context)
                ? AppTokens.buttonHeightLg
                : AppTokens.buttonHeightMd,
            child: ElevatedButton(
              onPressed: authProvider.state.isLoading
                  ? null
                  : _handleVerifyEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEB8A00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                ),
              ),
              child: authProvider.state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'تأكيد الحساب',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppTokens.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'لم يصلك الرمز؟',
                style: TextStyle(
                  color: AppColors.authTextColor(context),
                  fontSize: AppTokens.fontSizeSm,
                ),
              ),
              TextButton(
                onPressed: authProvider.state.isLoading
                    ? null
                    : _handleResendCode,
                child: const Text(
                  'إعادة الإرسال',
                  style: TextStyle(
                    color: Color(0xFFEB8A00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacing4),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text(
              'العودة لتسجيل الدخول',
              style: TextStyle(
                color: Color(0xFFEB8A00),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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

    return GlassContainer(
      isMobile: isMobile,
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
        return _buildAccountStep();
      case 1:
        return _buildProfileStep();
      case 2:
        return _buildGradeStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAccountStep() {
    return Column(
      children: [
        const StepHeader(
          title: 'بيانات الحساب',
          icon: Icons.lock_person_outlined,
        ),
        const SizedBox(height: AppTokens.spacing12),
        _buildTextField(
          controller: _emailController,
          label: AppStrings.email,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال البريد الإلكتروني';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'البريد الإلكتروني غير صالح';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTokens.spacing12),
        _buildTextField(
          controller: _passwordController,
          label: AppStrings.password,
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: _obscurePassword,
          onToggleVisibility: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          validator: (value) {
            if (value == null || value.isEmpty) return 'يرجى إدخال كلمة المرور';
            if (value.length < 6)
              return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
            return null;
          },
        ),
        const SizedBox(height: AppTokens.spacing12),
        _buildTextField(
          controller: _confirmPasswordController,
          label: AppStrings.confirmPassword,
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: _obscureConfirmPassword,
          onToggleVisibility: () => setState(
            () => _obscureConfirmPassword = !_obscureConfirmPassword,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'يرجى تأكيد كلمة المرور';
            if (value != _passwordController.text) {
              return 'كلمات المرور غير متطابقة';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProfileStep() {
    return Column(
      children: [
        const StepHeader(title: 'البيانات الشخصية', icon: Icons.badge_outlined),
        const SizedBox(height: AppTokens.spacing12),
        _buildTextField(
          controller: _fullNameController,
          label: AppStrings.fullName,
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال الاسم الكامل';
            }

            // Normalize أمة variations: امه, أمه, امة → أمة
            String normalized = value
                .replaceAll(
                  RegExp(r'[إأآا]ة$'),
                  'ة',
                ) // normalize taa marbuta ending
                .replaceAll(RegExp(r'امة$'), 'أمة') // امة → أمة
                .replaceAll(RegExp(r'امه$'), 'أمة') // امه → أمة
                .replaceAll(RegExp(r'أمه$'), 'أمة'); // أمه → أمة

            // Count words (split by spaces)
            final words = normalized.trim().split(RegExp(r'\s+'));

            if (words.length < 3) {
              return 'يرجى إدخال الاسم الثلاثي على الأقل';
            }
            if (!RegExp(r'^[\u0600-\u06FF\s]+$').hasMatch(value)) {
              return 'يجب أن يكون الاسم الكامل باللغة العربية فقط';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTokens.spacing12),
        _buildTextField(
          controller: _usernameController,
          label: AppStrings.username,
          icon: Icons.alternate_email,
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'يرجى إدخال اسم المستخدم';
            if (value.length < 3) {
              return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
            }
            if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) {
              return 'يجب أن يكون اسم المستخدم بالإنجليزية فقط (أحرف وأرقام)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildGradeStep() {
    return Column(
      children: [
        const StepHeader(
          title: 'المرحلة الدراسية',
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: AppTokens.spacing12),
        GradeSelector(
          selectedGrade: _selectedGrade,
          onChanged: (val) => setState(() => _selectedGrade = val),
        ),
        const SizedBox(height: AppTokens.spacing12),
        TermsAgreement(
          value: _termsAccepted,
          onChanged: (val) => setState(() => _termsAccepted = val ?? false),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isOtpField = controller == _otpController;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: isOtpField
          ? [
              FilteringTextInputFormatter.allow(
                RegExp(r'[0-9\u0660-\u0669\u06F0-\u06F9]'),
              ),
              LengthLimitingTextInputFormatter(8),
            ]
          : null,
      style: TextStyle(color: AppColors.authTextColor(context)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.authLabelColor(context)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.authLabelColor(context),
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: AppColors.glassBackgroundColor(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacing16,
          vertical: AppTokens.spacing12,
        ),
        labelStyle: TextStyle(color: AppColors.authLabelColor(context)),
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
      ),
      validator: validator,
    );
  }
}

class StepHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const StepHeader({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFEB8A00), size: 18),
        const SizedBox(width: AppTokens.spacing4),
        Text(
          title,
          style: TextStyle(
            color: AppColors.authHeaderColor(context),
            fontWeight: FontWeight.bold,
            fontSize: AppTokens.fontSizeLg,
          ),
        ),
      ],
    );
  }
}
