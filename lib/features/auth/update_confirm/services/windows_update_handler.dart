import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:arabilogia/core/services/update_service.dart';

class WindowsUpdateHandler {
  final String downloadUrl;
  final String fileName;
  final int fileSize;
  final String version;
  final String releaseNotes;
  final void Function(double progress, String status) onProgressUpdate;
  final void Function() onComplete;
  final void Function(String error) onError;
  final void Function(String message) onShowDownloadError;

  WindowsUpdateHandler({
    required this.downloadUrl,
    required this.fileName,
    required this.fileSize,
    required this.version,
    required this.releaseNotes,
    required this.onProgressUpdate,
    required this.onComplete,
    required this.onError,
    required this.onShowDownloadError,
  });

  void dispose() {}

  static String getFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      return pathSegments.last;
    }
    return 'arabilogia-update.exe';
  }

  Future<void> startUpdate(BuildContext context) async {
    onProgressUpdate(0, 'جاري تحميل التحديث للويندوز...');

    try {
      final tempDir = await getTemporaryDirectory();
      final name = getFileNameFromUrl(downloadUrl);
      final outputFile = File('${tempDir.path}/$name');

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(downloadUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('فشل التحميل: ${response.statusCode}');
      }

      final totalBytes = response.contentLength > 0 ? response.contentLength : fileSize;
      var receivedBytes = 0;

      final sink = outputFile.openWrite();
      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgressUpdate(
            receivedBytes / totalBytes,
            'جاري التحميل: ${(receivedBytes / 1024 / 1024).toStringAsFixed(1)} / ${(totalBytes / 1024 / 1024).toStringAsFixed(1)} MB',
          );
        }
      }
      await sink.close();
      client.close();

      onProgressUpdate(1.0, 'تم التحميل، جاري التثبيت...');

      final success = await _runInstaller(outputFile.path);
      if (!context.mounted) return;
      if (success) {
        onProgressUpdate(1.0, 'جاري التثبيت...');
      } else {
        _showInstallInstructions(context, outputFile.path);
      }

      UpdateService.storeWhatsNewNotes(version, releaseNotes);
    } catch (e) {
      onError('فشل: $e');
      onShowDownloadError(e.toString());
    }

    onComplete();
  }

  Future<bool> _runInstaller(String installerPath) async {
    try {
      final result = await Process.run('cmd', [
        '/c',
        'start',
        '',
        installerPath,
      ]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  void _showInstallInstructions(BuildContext context, String installerPath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('تم التحميل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تم تحميل تحديث الويندوز بنجاح.'),
            const SizedBox(height: 12),
            const Text('لتثبيت التحديث:'),
            Text('1. افتح المجلد: $installerPath'),
            const Text('2. شغّل ملف التثبيت'),
            const Text('3. اتبع خطوات التثبيت'),
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
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Process.run('explorer', ['/select,', installerPath]);
            },
            child: const Text('فتح الموقع'),
          ),
        ],
      ),
    );
  }
}
