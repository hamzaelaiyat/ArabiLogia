import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/legal_content.dart';

class LegalBottomSheet extends StatelessWidget {
  final String title;
  final List<Map<String, String>> sections;
  final bool isDialog;

  const LegalBottomSheet({
    super.key,
    required this.title,
    required this.sections,
    this.isDialog = false,
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
    final isMobile = AppTokens.isMobile(context);

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        isScrollControlled: true,
        enableDrag: true,
        useRootNavigator: true,
        builder: (context) => LegalBottomSheet(title: title, sections: sections),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: LegalBottomSheet(
            title: title,
            sections: sections,
            isDialog: true,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: isDialog
            ? EdgeInsets.zero
            : EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: isDialog ? 600 : maxHeight),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              AppTokens.spacing24,
              isDialog ? AppTokens.spacing24 : 0,
              AppTokens.spacing24,
              AppTokens.spacing32,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: isDialog
                  ? BorderRadius.circular(32)
                  : const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isDialog) _buildDragHandle(context),
                if (!isDialog) const SizedBox(height: AppTokens.spacing8),
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
                            'آخر تحديث: ${LegalContent.lastUpdated}',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? Colors.white30 : Colors.black26,
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
