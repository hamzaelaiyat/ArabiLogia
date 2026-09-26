import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class SidebarLegalAccordion extends StatefulWidget {
  final bool showLabels;
  final VoidCallback onAboutTap;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  const SidebarLegalAccordion({
    super.key,
    required this.showLabels,
    required this.onAboutTap,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  @override
  State<SidebarLegalAccordion> createState() => _SidebarLegalAccordionState();
}

class _SidebarLegalAccordionState extends State<SidebarLegalAccordion>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  void _toggleAccordion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showLabels) {
      return IconButton(
        icon: const Icon(Icons.policy_outlined, size: 20),
        tooltip: 'القانون',
        onPressed: widget.onTermsTap,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Darker background behind sub-items when accordion opens upwards
    final darkerSubItemsBg = isDark
        ? const Color(0xFF111315)
        : const Color(0xFFD3E7FA);

    // Header label text: "القانون" when closed/compact, "المنصة والقانون" when expanded/extended
    final headerText = (_isExpanded || widget.showLabels)
        ? 'المنصة والقانون'
        : 'القانون';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1) Upward Expansion Sub-Items Box (placed ABOVE the header so the header position stays fixed!)
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.bottomCenter,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: darkerSubItemsBg,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. About / عن المنصة
                        _buildSubNavItem(
                          icon: Icons.info_outline,
                          label: 'عن المنصة',
                          onTap: widget.onAboutTap,
                          context: context,
                        ),
                        // 2. Terms / الشروط والأحكام
                        _buildSubNavItem(
                          icon: Icons.description_outlined,
                          label: 'الشروط والأحكام',
                          onTap: widget.onTermsTap,
                          context: context,
                        ),
                        // 3. Privacy / سياسة الخصوصية
                        _buildSubNavItem(
                          icon: Icons.privacy_tip_outlined,
                          label: 'سياسة الخصوصية',
                          onTap: widget.onPrivacyTap,
                          context: context,
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // 2) Accordion Header Bar at the Far Bottom of the Sidebar
        InkWell(
          onTap: _toggleAccordion,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacing12,
              vertical: AppTokens.spacing10,
            ),
            decoration: BoxDecoration(
              color: _isExpanded
                  ? (isDark
                        ? Colors.white12
                        : Colors.black.withValues(alpha: 0.05))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.policy_outlined,
                  size: 20,
                  color: AppColors.mutedColor(context),
                ),
                const SizedBox(width: AppTokens.spacing12),
                Expanded(
                  child: Text(
                    headerText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacing12,
          vertical: 8.0,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.mutedColor(context)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
