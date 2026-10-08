import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/widgets/responsive_overlay.dart';

class LectureExitConfirmationSheet {
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onExitWithoutSaving,
    required Future<void> Function() onSaveAsDraft,
    required Future<void> Function() onSaveAndPublish,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveOverlay.show(
      context: context,
      title: 'الخروج من المحاضرة',
      mobileBuilder: (_) => _ExitConfirmationContent(
        isDark: isDark,
        width: null,
        onCancel: () => Navigator.pop(context),
        onExitWithoutSaving: () {
          Navigator.pop(context);
          onExitWithoutSaving();
        },
        onSaveAsDraft: () async {
          Navigator.pop(context);
          await onSaveAsDraft();
        },
        onSaveAndPublish: () async {
          Navigator.pop(context);
          await onSaveAndPublish();
        },
      ),
      desktopBuilder: (_) => _ExitConfirmationContent(
        isDark: isDark,
        width: null,
        onCancel: () => Navigator.pop(context),
        onExitWithoutSaving: () {
          Navigator.pop(context);
          onExitWithoutSaving();
        },
        onSaveAsDraft: () async {
          Navigator.pop(context);
          await onSaveAsDraft();
        },
        onSaveAndPublish: () async {
          Navigator.pop(context);
          await onSaveAndPublish();
        },
      ),
    );
  }
}

class _ExitConfirmationContent extends StatelessWidget {
  final bool isDark;
  final double? width;
  final VoidCallback onCancel;
  final VoidCallback onExitWithoutSaving;
  final VoidCallback onSaveAsDraft;
  final VoidCallback onSaveAndPublish;

  const _ExitConfirmationContent({
    required this.isDark,
    this.width,
    required this.onCancel,
    required this.onExitWithoutSaving,
    required this.onSaveAsDraft,
    required this.onSaveAndPublish,
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
            'الخروج من المحاضرة',
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
                  onPressed: onExitWithoutSaving,
                  child: const Text('الخروج بدون حفظ'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSaveAsDraft,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('حفظ كمسودة'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSaveAndPublish,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: const Text('حفظ ونشر'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onCancel, child: const Text('إلغاء')),
        ],
      ),
    );
  }
}
