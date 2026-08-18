import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/auth/widgets/theme_toggle_button.dart';

class AuthLayout extends StatelessWidget {
  final Widget formChild;
  final bool showThemeToggle;

  const AuthLayout({
    super.key,
    required this.formChild,
    this.showThemeToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AppTokens.isMobile(context);
    final bgColor = AppColors.authBackground(context);

    final illustrationAsset = isDark
        ? 'assets/images/image-darkmode.png'
        : 'assets/images/image-lightmode.png';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
                child: isMobile
                    ? _buildMobileLayout(context)
                    : _buildDesktopLayout(context, illustrationAsset),
              ),
            ),
            if (showThemeToggle && isMobile)
              const Positioned(
                top: 16,
                right: 16,
                child: MobileTheme3DotsMenu(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, String illustrationAsset) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 1400,
          maxHeight: 900,
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Side: Illustration Card (~70% width)
              Expanded(
                flex: 70,
                child: Container(
                  margin: const EdgeInsets.only(left: 12, right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            illustrationAsset,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (showThemeToggle)
                          const Positioned(
                            bottom: 20,
                            left: 20,
                            child: ThemeToggleButton(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Right Side: Form Content Panel (~30% width)
              Expanded(
                flex: 30,
                child: Container(
                  margin: const EdgeInsets.only(left: 12, right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1D2023) : const Color(0xFFE5F3FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: formChild,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: formChild,
      ),
    );
  }
}
