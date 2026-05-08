import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/auth/widgets/auth_text_field.dart';
import 'package:arabilogia/features/auth/widgets/glass_container.dart';

String normalizeOtp(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    final codePoint = rune;
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

class EmailVerificationCard extends StatefulWidget {
  final String email;
  final bool isLoading;
  final String? error;
  final ValueChanged<String> onVerify;
  final VoidCallback onResend;
  final VoidCallback onBackToLogin;

  const EmailVerificationCard({
    super.key,
    required this.email,
    required this.isLoading,
    this.error,
    required this.onVerify,
    required this.onResend,
    required this.onBackToLogin,
  });

  @override
  State<EmailVerificationCard> createState() => _EmailVerificationCardState();
}

class _EmailVerificationCardState extends State<EmailVerificationCard> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _handleVerify() {
    if (_formKey.currentState!.validate()) {
      final otp = normalizeOtp(_otpController.text);
      widget.onVerify(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTokens.isMobile(context);

    return GlassContainer(
      isMobile: isMobile,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing24,
        vertical: AppTokens.spacing32,
      ),
      child: Form(
        key: _formKey,
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
              widget.email,
              style: const TextStyle(
                color: Color(0xFFEB8A00),
                fontWeight: FontWeight.bold,
                fontSize: AppTokens.fontSizeMd,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spacing24),
            AuthTextField(
              controller: _otpController,
              label: 'رمز التفعيل',
              icon: Icons.vpn_key_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9\u0660-\u0669\u06F0-\u06F9]'),
                ),
                LengthLimitingTextInputFormatter(8),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) return 'يرجى إدخال الرمز';
                final normalized = normalizeOtp(value);
                if (normalized.length < 6 || normalized.length > 8) {
                  return 'يجب أن يكون الرمز من 6 إلى 8 أرقام';
                }
                return null;
              },
            ),
            if (widget.error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.spacing12),
                child: Text(
                  widget.error!,
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
                onPressed: widget.isLoading ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEB8A00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  ),
                ),
                child: widget.isLoading
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
                  onPressed: widget.isLoading ? null : widget.onResend,
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
              onPressed: widget.onBackToLogin,
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
      ),
    );
  }
}
