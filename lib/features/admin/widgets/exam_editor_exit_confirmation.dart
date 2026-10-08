import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/widgets/responsive_overlay.dart';

class ExamEditorExitConfirmation {
  static void show({
    required BuildContext context,
    required VoidCallback onCancel,
    required VoidCallback onSaveDraft,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ResponsiveOverlay.show(
      context: context,
      title: 'الخروج من المحرر',
      mobileBuilder: (_) => _ExitConfirmationContent(
        isDark: isDark,
        width: null,
        onCancel: () {
          Navigator.pop(context);
          onCancel();
        },
        onSaveDraft: () {
          Navigator.pop(context);
          onSaveDraft();
          onCancel();
        },
      ),
      desktopBuilder: (_) => _ExitConfirmationContent(
        isDark: isDark,
        width: null,
        onCancel: () {
          Navigator.pop(context);
          onCancel();
        },
        onSaveDraft: () {
          Navigator.pop(context);
          onSaveDraft();
          onCancel();
        },
      ),
    );
  }
}

class _ExitConfirmationContent extends StatelessWidget {
  final bool isDark;
  final double? width;
  final VoidCallback onCancel;
  final VoidCallback onSaveDraft;

  const _ExitConfirmationContent({
    required this.isDark,
    this.width,
    required this.onCancel,
    required this.onSaveDraft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232527) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.exit_to_app, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'الخروج من المحرر',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'هل تريد حفظ التغييرات قبل الخروج؟',
            style: TextStyle(color: AppColors.mutedColor(context)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('الخروج بدون حفظ'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSaveDraft,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('حفظ وخروج'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }
}
