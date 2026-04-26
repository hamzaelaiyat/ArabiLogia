import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/legal_content.dart';
import 'package:arabilogia/features/auth/widgets/glass_container.dart';

class LegalBottomSheet extends StatelessWidget {
  final String title;
  final List<Map<String, String>> sections;

  const LegalBottomSheet({
    super.key,
    required this.title,
    required this.sections,
  });

  static void showTerms(BuildContext context) {
    _show(context, LegalContent.termsTitle, LegalContent.termsSections);
  }

  static void showPrivacy(BuildContext context) {
    _show(context, LegalContent.privacyTitle, LegalContent.privacySections);
  }

  static void showAbout(BuildContext context) {
    _show(context, LegalContent.aboutTitle, LegalContent.aboutSections);
  }

  static void _show(
      BuildContext context, String title, List<Map<String, String>> sections) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => LegalBottomSheet(title: title, sections: sections),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTokens.isMobile(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: GlassContainer(
            isMobile: isMobile,
            padding: EdgeInsets.fromLTRB(
              AppTokens.spacing24,
              0, // Handle provides top spacing
              AppTokens.spacing24,
              AppTokens.spacing32,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            blur: 50.0,
            opacity: 0.85, 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDragHandle(context),
                const SizedBox(height: AppTokens.spacing8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEB8A00),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.spacing24),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...sections.map((section) => _buildSection(context,
                            section['title']!, section['content']!)),
                        const SizedBox(height: AppTokens.spacing16),
                        Center(
                          child: Text(
                            'آخر تحديث: أبريل 2026',
                            style: TextStyle(
                              color: AppColors.authLabelColor(context),
                              fontSize: AppTokens.fontSizeSm,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.spacing16),
                SizedBox(
                  width: double.infinity,
                  height: AppTokens.buttonHeightMd,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEB8A00),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                      ),
                    ),
                    child: const Text(
                      'حسناً',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.authHeaderColor(context),
              fontWeight: FontWeight.bold,
              fontSize: AppTokens.fontSizeLg,
            ),
          ),
          const SizedBox(height: AppTokens.spacing4),
          Text(
            content,
            style: TextStyle(
              color: AppColors.authTextColor(context),
              height: 1.6,
              fontSize: AppTokens.fontSizeMd,
            ),
          ),
        ],
      ),
    );
  }
}
