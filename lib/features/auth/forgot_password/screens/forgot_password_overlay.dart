import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/features/auth/widgets/glass_container.dart';
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
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        isScrollControlled: true,
        enableDrag: true,
        builder: (context) => const ForgotPasswordOverlay(),
      );
    }

    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const ForgotPasswordOverlay(),
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
      setState(() => _errorMessage = 'فشل في إرسال رابط إعادة التعيين. يرجى التحقق من البريد الإلكتروني.');
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
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppTokens.spacing8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: _buildContent(context, false),
        ),
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isMobile) {
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
    );

    return GlassContainer(
      isMobile: isMobile,
      padding: EdgeInsets.fromLTRB(
        AppTokens.spacing24,
        isMobile ? 0 : AppTokens.spacing12,
        AppTokens.spacing24,
        AppTokens.spacing32,
      ),
      borderRadius: isMobile
          ? const BorderRadius.vertical(top: Radius.circular(32))
          : BorderRadius.circular(24),
      blur: 50.0,
      opacity: 0.6,
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
            const SizedBox(height: AppTokens.spacing12),
            Image.asset(
              'assets/images/logo-removedbg.png',
              height: 80,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppTokens.spacing12),
            Text(
              AppStrings.forgotPassword,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.authHeaderColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spacing8),
            Text(
              _isSubmitted
                  ? 'تم إرسال رمز إعادة التعيين المكون من 6 أرقام إلى بريدك الإلكتروني'
                  : 'أدخل بريدك الإلكتروني لإرسال رمز إعادة التعيين المكون من 6 أرقام',
              style: TextStyle(
                color: AppColors.authTextColor(context),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spacing24),
            if (!_isSubmitted) ...[
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
              const SizedBox(height: AppTokens.spacing20),
              _buildActionButton(context, 'إرسال الرمز'),
            ] else ...[
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppColors.authTextColor(context)),
                decoration: cloudyInputDecoration.copyWith(
                  labelText: 'رمز التفعيل',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'يرجى إدخال الرمز';
                  if (value.length != 6) return 'الرمز يجب أن يكون 6 أرقام';
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.spacing16),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(AppTokens.spacing12),
                  margin: const EdgeInsets.only(bottom: AppTokens.spacing12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(color: const Color(0xFFD32F2F)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFD32F2F),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: AppColors.authTextColor(context)),
                decoration: cloudyInputDecoration.copyWith(
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
              _buildActionButton(context, 'تغيير كلمة المرور'),
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

  Widget _buildActionButton(BuildContext context, String label) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return Column(
          children: [
            Container(
              width: double.infinity,
              height: AppTokens.isMobile(context)
                  ? AppTokens.buttonHeightLg
                  : AppTokens.buttonHeightMd,
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
                onPressed: auth.state.isLoading
                    ? null
                    : (_isSubmitted ? _handleVerifyAndReset : _handleReset),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
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
                        label,
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
          ],
        );
      },
    );
  }
}
