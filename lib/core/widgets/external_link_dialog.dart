import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/desktop_confirm_dialog.dart';

/// Only http(s) links are allowed. Blocks `javascript:`, `data:`, `file:` and
/// custom app schemes that lecture content could otherwise smuggle in.
bool isWebLink(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return false;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return false;
  return uri.host.isNotEmpty;
}

/// Host plus path, so the reader can spot a disguised destination before
/// leaving. Falls back to the raw link when the host cannot be read.
String externalLinkDisplayTarget(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.host.isEmpty) return url.trim();
  final path = (uri.path.isEmpty || uri.path == '/') ? '' : uri.path;
  return '${uri.host}$path';
}

Future<bool> showExternalLinkWarningDialog(
  BuildContext context,
  String url,
) async {
  final target = externalLinkDisplayTarget(url);
  final message =
      'سيتم فتح هذا الرابط في المتصفح أو تطبيق خارجي:\n\n$target\n\n'
      'المحتوى من طرف ثالث، ولا نتحمل مسؤولية ما يحتويه.';

  if (AppTokens.isDesktop(context)) {
    final result = await DesktopConfirmDialog.show<bool>(
      context: context,
      title: 'أنت على وشك مغادرة الموقع',
      message: message,
      confirmLabel: 'فتح الرابط',
      cancelLabel: 'إلغاء',
      confirmColor: AppColors.primary,
      onConfirm: () => Navigator.pop(context, true),
    );
    return result ?? false;
  }

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('أنت على وشك مغادرة الموقع'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('فتح الرابط'),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
