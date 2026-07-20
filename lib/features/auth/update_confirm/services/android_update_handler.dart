import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arabilogia/core/services/update_service.dart';

class AndroidUpdateHandler {
  final String downloadUrl;
  final String fileName;
  final int fileSize;
  final String version;
  final String releaseNotes;
  final void Function(double progress, String status) onProgressUpdate;
  final void Function() onComplete;
  final void Function(String error) onError;
  final void Function(String url) onFallbackToBrowser;

  AndroidUpdateHandler({
    required this.downloadUrl,
    required this.fileName,
    required this.fileSize,
    required this.version,
    required this.releaseNotes,
    required this.onProgressUpdate,
    required this.onComplete,
    required this.onError,
    required this.onFallbackToBrowser,
  });

  static const _platform = MethodChannel('com.arabilogia.app/download');
  int? _downloadId;
  Timer? _progressTimer;

  Future<void> startUpdate(BuildContext context) async {
    final hasInstallPermission = await _platform.invokeMethod<bool>(
      'canRequestPackageInstalls',
    );
    if (!context.mounted) return;
    if (hasInstallPermission != true) {
      final granted = await _requestInstallPermission(context);
      if (granted != true) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى السماح بتثبيت التطبيقات من مصادر غير معروفة'),
          ),
        );
        return;
      }
    }
    if (!context.mounted) return;
    await _updateAndroid(context);
  }

  void dispose() {
    _progressTimer?.cancel();
  }

  Future<bool?> _requestInstallPermission(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('السماح بتثبيت التطبيقات'),
        content: const Text(
          'للتحديث، يجب السماح بتثبيت التطبيقات من مصادر غير معروفة.\n'
          'سيتم فتح إعدادات الجهاز. يرجى تفعيل الخيار ثم العودة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );

    await _platform.invokeMethod('requestPackageInstallPermission');
    return true;
  }

  Future<void> _updateAndroid(BuildContext context) async {
    onProgressUpdate(0, 'جاري تحميل التحديث...');

    try {
      final result = await _platform.invokeMethod<Map>('startDownload', {
        'url': downloadUrl,
        'fileName': fileName,
      });

      if (result != null && result['downloadId'] != null) {
        _downloadId = result['downloadId'] as int;
        onProgressUpdate(0, 'التميل جارٍ...');
        if (!context.mounted) return;
        _startProgressMonitoring(context);
      } else {
        _fallbackToBrowser();
      }
    } on PlatformException catch (_) {
      _fallbackToBrowser();
    } catch (_) {
      _fallbackToBrowser();
    }
  }

  void _startProgressMonitoring(BuildContext context) {
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_downloadId == null) {
        timer.cancel();
        return;
      }

      try {
        final progress = await _platform.invokeMethod<Map>('getProgress', {
          'downloadId': _downloadId,
        });
        if (progress != null) {
          final bytesDownloaded = progress['bytesDownloaded'] as int? ?? 0;
          final totalBytes =
              progress['totalBytes'] as int? ?? fileSize;

          if (totalBytes > 0) {
            onProgressUpdate(
              bytesDownloaded / totalBytes,
              'جاري التحميل: ${(bytesDownloaded / 1024 / 1024).toStringAsFixed(1)} / ${(totalBytes / 1024 / 1024).toStringAsFixed(1)} MB',
            );
          }

          final status = progress['status'] as int?;
          if (status == 8) {
            timer.cancel();
            if (!context.mounted) return;
            _onDownloadComplete(context);
            return;
          } else if (status == 16) {
            timer.cancel();
            onError('فشل التحميل');
            return;
          }
        }
      } catch (e) {
        debugPrint('Progress polling error: $e');
      }
    });
  }

  Future<void> _onDownloadComplete(BuildContext context) async {
    onProgressUpdate(1.0, 'تم التحميل بنجاح!');

    await Future.delayed(const Duration(milliseconds: 500));

    final installed = await _platform.invokeMethod<bool>('installApk', {
      'downloadId': _downloadId,
      'fileName': fileName,
    });

    if (installed == true) {
      onProgressUpdate(1.0, 'جاري التثبيت...');
    } else {
      if (!context.mounted) return;
      _showInstallInstructionsDialog(context);
    }
  }

  void _fallbackToBrowser() {
    onFallbackToBrowser(downloadUrl);
  }

  void _showInstallInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('تم التحميل'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. انقر على الإشعار في شريط التنزيلات'),
            Text('2. فعّل "السماح من مصادر غير معروفة" إذا طُلب'),
            Text('3. تابع خطوات التثبيت'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              UpdateService.storeWhatsNewNotes(version, releaseNotes);
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}
