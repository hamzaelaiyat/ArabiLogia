import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:arabilogia/core/services/update_service.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class UpdateConfirmPage extends StatefulWidget {
  final AppUpdate update;

  const UpdateConfirmPage({super.key, required this.update});

  @override
  State<UpdateConfirmPage> createState() => _UpdateConfirmPageState();
}

class _UpdateConfirmPageState extends State<UpdateConfirmPage> {
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String _status = '';
  int? _downloadId;
  Timer? _progressTimer;
  static const _platform = MethodChannel('com.arabilogia.app/download');

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.update.isMandatory ? 'تحديث إلزامي' : 'يتوفر تحديث جديد',
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFEB8A00).withAlpha(25),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.system_update,
                size: 50,
                color: Color(0xFFEB8A00),
              ),
            ),
            const SizedBox(height: AppTokens.spacing24),

            Text(
              'إصدار جديد: ${widget.update.version}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTokens.spacing8),

            Text(
              'حجم التحديث: ${_formatFileSize(widget.update.fileSize)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: AppTokens.spacing24),

            if (widget.update.releaseNotes.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTokens.spacing16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.new_releases_outlined,
                          size: 20,
                          color: Color(0xFFEB8A00),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'ما الجديد؟',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spacing12),
                    Text(
                      widget.update.releaseNotes,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spacing24),
            ],

            if (widget.update.isMandatory)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTokens.spacing16),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'هذا التحديث إلزامي لإصلاح مشاكل أمنية مهمة',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppTokens.spacing32),

            if (_isDownloading) ...[
              LinearProgressIndicator(value: _downloadProgress),
              const SizedBox(height: AppTokens.spacing12),
              Text(_status, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: AppTokens.spacing24),
            ],

            if (!_isDownloading) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEB8A00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'تحديث الآن',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spacing12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _remindLater,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFEB8A00)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ذكرني لاحقاً',
                    style: TextStyle(color: Color(0xFFEB8A00), fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spacing12),

              TextButton(
                onPressed: _skipUpdate,
                child: Text(
                  'تخطي هذه النسخة',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _startUpdate() async {
    if (Platform.isAndroid) {
      await _updateAndroid();
    } else if (Platform.isWindows) {
      await _updateWindows();
    } else if (Platform.isLinux) {
      await _updateLinux();
    }
  }

  Future<void> _updateAndroid() async {
    setState(() {
      _isDownloading = true;
      _status = 'جاري تحميل التحديث...';
      _downloadProgress = 0;
    });

    try {
      final result = await _platform.invokeMethod<Map>('startDownload', {
        'url': widget.update.downloadUrl,
        'fileName': widget.update.fileName,
      });

      if (result != null && result['downloadId'] != null) {
        _downloadId = result['downloadId'] as int;
        setState(() => _status = 'التميل جارٍ...');

        _startProgressMonitoring();
      } else {
        _fallbackToBrowser();
      }
    } on PlatformException catch (e) {
      debugPrint('DownloadManager error: ${e.message}');
      _fallbackToBrowser();
    } catch (e) {
      debugPrint('Download error: $e');
      _fallbackToBrowser();
    }
  }

  void _startProgressMonitoring() {
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_downloadId == null || !mounted) {
        timer.cancel();
        return;
      }

      try {
        final progress = await _platform.invokeMethod<Map>('getProgress', {
          'downloadId': _downloadId,
        });
        if (progress != null && mounted) {
          final bytesDownloaded = progress['bytesDownloaded'] as int? ?? 0;
          final totalBytes =
              progress['totalBytes'] as int? ?? widget.update.fileSize;

          if (totalBytes > 0) {
            setState(() {
              _downloadProgress = bytesDownloaded / totalBytes;
              _status =
                  'جاري التحميل: ${(bytesDownloaded / 1024 / 1024).toStringAsFixed(1)} / ${(totalBytes / 1024 / 1024).toStringAsFixed(1)} MB';
            });
          }

          final status = progress['status'] as int?;
          if (status == 8 || status == 16) {
            timer.cancel();
            _onDownloadComplete();
          } else if (status == 16 || status == 0) {
            timer.cancel();
            _onDownloadComplete();
          }
        }
      } catch (e) {
        debugPrint('Progress check error: $e');
      }
    });
  }

  Future<void> _onDownloadComplete() async {
    if (!mounted) return;

    setState(() {
      _downloadProgress = 1.0;
      _status = 'تم التحميل بنجاح!';
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final installed = await _platform.invokeMethod<bool>('installApk', {
      'downloadId': _downloadId,
      'fileName': widget.update.fileName,
    });

    if (!mounted) return;

    if (installed == true) {
      setState(() => _status = 'جاري التثبيت...');
    } else {
      _showInstallInstructionsDialog();
    }
  }

  void _fallbackToBrowser() {
    setState(() => _isDownloading = false);

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
              final uri = Uri.parse(widget.update.downloadUrl);
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

  void _showInstallInstructionsDialog() {
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
              UpdateService.storeWhatsNewNotes(
                widget.update.version,
                widget.update.releaseNotes,
              );
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateWindows() async {
    setState(() {
      _isDownloading = true;
      _status = 'جاري تحميل التحديث للويندوز...';
      _downloadProgress = 0;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = _getFileNameFromUrl(widget.update.downloadUrl);
      final outputFile = File('${tempDir.path}/$fileName');

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(widget.update.downloadUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('فشل التحميل: ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? widget.update.fileSize;
      var receivedBytes = 0;

      final sink = outputFile.openWrite();
      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (mounted && totalBytes > 0) {
          setState(() {
            _downloadProgress = receivedBytes / totalBytes;
            _status =
                'جاري التحميل: ${(receivedBytes / 1024 / 1024).toStringAsFixed(1)} / ${(totalBytes / 1024 / 1024).toStringAsFixed(1)} MB';
          });
        }
      }
      await sink.close();
      client.close();

      setState(() {
        _downloadProgress = 1.0;
        _status = 'تم التحميل، جاري التثبيت...';
      });

      if (mounted) {
        final success = await _runWindowsInstaller(outputFile.path);
        if (success) {
          setState(() => _status = 'جاري التثبيت...');
        } else {
          _showWindowsInstallInstructions(outputFile.path);
        }
      }

      UpdateService.storeWhatsNewNotes(
        widget.update.version,
        widget.update.releaseNotes,
      );
    } catch (e) {
      debugPrint('Windows download error: $e');
      setState(() => _status = 'فشل: $e');
      _showDownloadError(e.toString());
    }

    setState(() => _isDownloading = false);
  }

  String _getFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      return pathSegments.last;
    }
    return 'arabilogia-update.exe';
  }

  Future<bool> _runWindowsInstaller(String installerPath) async {
    try {
      final result = await Process.run('cmd', [
        '/c',
        'start',
        '',
        installerPath,
      ]);
      debugPrint('Installer started: ${result.exitCode}');
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Failed to run installer: $e');
      return false;
    }
  }

  void _showWindowsInstallInstructions(String installerPath) {
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
              UpdateService.storeWhatsNewNotes(
                widget.update.version,
                widget.update.releaseNotes,
              );
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

  Future<void> _updateLinux() async {
    setState(() {
      _isDownloading = true;
      _status = 'جاري تحميل التحديث للينكس...';
      _downloadProgress = 0;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = _getFileNameFromUrl(widget.update.downloadUrl);
      final outputFile = File('${tempDir.path}/$fileName');

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(widget.update.downloadUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('فشل التحميل: ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? widget.update.fileSize;
      var receivedBytes = 0;

      final sink = outputFile.openWrite();
      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (mounted && totalBytes > 0) {
          setState(() {
            _downloadProgress = receivedBytes / totalBytes;
            _status =
                'جاري التحميل: ${(receivedBytes / 1024 / 1024).toStringAsFixed(1)} / ${(totalBytes / 1024 / 1024).toStringAsFixed(1)} MB';
          });
        }
      }
      await sink.close();
      client.close();

      setState(() {
        _downloadProgress = 1.0;
        _status = 'تم التحميل';
      });

      final fileExtension = fileName.split('.').last.toLowerCase();

      if (fileExtension == 'deb') {
        final success = await _installDebPackage(outputFile.path);
        if (!success) {
          _showLinuxInstallInstructions(outputFile.path, 'deb');
        }
      } else if (fileExtension == 'AppImage' || fileName.contains('AppImage')) {
        await _makeAppImageExecutable(outputFile.path);
        _showLinuxInstallInstructions(outputFile.path, 'AppImage');
      } else if (fileExtension == 'rpm') {
        final success = await _installRpmPackage(outputFile.path);
        if (!success) {
          _showLinuxInstallInstructions(outputFile.path, 'rpm');
        }
      } else {
        _showLinuxInstallInstructions(outputFile.path, 'unknown');
      }

      UpdateService.storeWhatsNewNotes(
        widget.update.version,
        widget.update.releaseNotes,
      );
    } catch (e) {
      debugPrint('Linux download error: $e');
      setState(() => _status = 'فشل: $e');
      _showDownloadError(e.toString());
    }

    setState(() => _isDownloading = false);
  }

  Future<bool> _installDebPackage(String debPath) async {
    try {
      final result = await Process.run('pkexec', ['dpkg', '-i', debPath]);
      if (result.exitCode == 0) {
        return true;
      }
      return false;
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
    } catch (e) {
      debugPrint('Failed to make AppImage executable: $e');
    }
  }

  void _showLinuxInstallInstructions(String filePath, String type) {
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
              UpdateService.storeWhatsNewNotes(
                widget.update.version,
                widget.update.releaseNotes,
              );
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showDownloadError(String message) {
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
              if (Platform.isWindows) {
                _updateWindows();
              } else if (Platform.isLinux) {
                _updateLinux();
              }
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _remindLater() async {
    await UpdateService.remindLater();
    if (mounted) Navigator.pop(context);
  }

  void _skipUpdate() async {
    await UpdateService.skipVersion(widget.update.version);
    if (mounted) Navigator.pop(context);
  }
}
