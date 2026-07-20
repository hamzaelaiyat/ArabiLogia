import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:arabilogia/core/services/update_service.dart';

class LinuxUpdateHandler {
  final String downloadUrl;
  final String fileName;
  final int fileSize;
  final String version;
  final String releaseNotes;
  final void Function(double progress, String status) onProgressUpdate;
  final void Function() onComplete;
  final void Function(String error) onError;
  final void Function(String message) onShowDownloadError;

  LinuxUpdateHandler({
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

  static String _getFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) return pathSegments.last;
    return 'arabilogia-update';
  }

  Future<void> startUpdate(BuildContext context) async {
    onProgressUpdate(0, 'جاري تحميل التحديث للينكس...');

    try {
      final tempDir = await getTemporaryDirectory();
      final name = _getFileNameFromUrl(downloadUrl);
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

      onProgressUpdate(1.0, 'تم التحميل');

      if (!context.mounted) return;
      final fileExtension = name.split('.').last.toLowerCase();

      if (fileExtension == 'deb') {
        final success = await _installDebPackage(outputFile.path);
        if (!success) {
          if (!context.mounted) return;
          _showInstallInstructions(context, outputFile.path, 'deb');
        }
      } else if (fileExtension == 'AppImage' || name.contains('AppImage')) {
        await _makeAppImageExecutable(outputFile.path);
        if (!context.mounted) return;
        _showInstallInstructions(context, outputFile.path, 'AppImage');
      } else if (fileExtension == 'rpm') {
        final success = await _installRpmPackage(outputFile.path);
        if (!success) {
          if (!context.mounted) return;
          _showInstallInstructions(context, outputFile.path, 'rpm');
        }
      } else {
        _showInstallInstructions(context, outputFile.path, 'unknown');
      }

      UpdateService.storeWhatsNewNotes(version, releaseNotes);
    } catch (e) {
      onError('فشل: $e');
      onShowDownloadError(e.toString());
    }

    onComplete();
  }

  Future<bool> _installDebPackage(String debPath) async {
    try {
      final result = await Process.run('pkexec', ['dpkg', '-i', debPath]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _installRpmPackage(String rpmPath) async {
    try {
      final result = await Process.run('pkexec', ['rpm', '-ivh', rpmPath]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<void> _makeAppImageExecutable(String appImagePath) async {
    try {
      await Process.run('chmod', ['+x', appImagePath]);
    } catch (e) {}
  }

  void _showInstallInstructions(
    BuildContext context,
    String filePath,
    String type,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('تم التحميل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تم تحميل تحديث اللينكس بنجاح.'),
            const SizedBox(height: 12),
            if (type == 'deb') ...[
              const Text('لتثبيت حزمة .deb:'),
              Text('1. شغّل: sudo dpkg -i $filePath'),
              const Text(
                '2. أو انقر بزر الماوس الأيمن على الملف واختر "تثبيت"',
              ),
            ] else if (type == 'AppImage') ...[
              const Text('للتشغيل كـ AppImage:'),
              Text('1. اجعل الملف قابلاً للتنفيذ: chmod +x $filePath'),
              const Text('2. شغّل الملف'),
            ] else if (type == 'rpm') ...[
              const Text('لتثبيت حزمة .rpm:'),
              Text('1. شغّل: sudo rpm -ivh $filePath'),
            ] else ...[
              Text('ملف التحديث: $filePath'),
              const Text('يرجى تثبيت التحديث يدوياً.'),
            ],
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
