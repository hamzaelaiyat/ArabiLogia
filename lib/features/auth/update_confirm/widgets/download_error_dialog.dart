import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void showDownloadErrorDialog(
  BuildContext context,
  String message,
  VoidCallback onRetry,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('خطأ في التحميل'),
      content: Text('فشل تحميل التحديث: $message'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            onRetry();
          },
          child: const Text('إعادة المحاولة'),
        ),
      ],
    ),
  );
}

void showBrowserFallbackDialog(BuildContext context, String url) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('تحميل من المتصفح'),
      content: const Text(
        'سيتم فتح المتصفح لتحميل التحديث. بعد التحميل، يرجى تثبيت التحديث يدوياً.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: const Text('فتح المتصفح'),
        ),
      ],
    ),
  );
}
