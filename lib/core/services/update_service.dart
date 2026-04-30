import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app_installer_plus/app_installer_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling app updates from GitHub Releases
/// Supports incremental patches and full APK downloads
class UpdateService {
  // GitHub repository configuration
  static const String _owner = 'hamzaelaiyat';
  static const String _repo = 'ArabiLogia';

  // Storage keys
  static const String _skippedVersionKey = 'skipped_update_version';
  static const String _lastCheckKey = 'last_update_check';
  static const String _installedVersionKey = 'installed_version';

  // Minimum time between update checks (24 hours)
  static const Duration _minCheckInterval = Duration(hours: 24);

  /// Get current app version from package_info_plus
  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Check for updates and show dialog if available
  /// Called from main.dart after app initialization
  static Future<void> checkForUpdates(BuildContext context) async {
    // Check if enough time has passed since last check
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastCheck < _minCheckInterval.inMilliseconds) {
      debugPrint('Skipping update check - within cooldown period');
      return;
    }

    String currentVersion;
    try {
      currentVersion = await getCurrentVersion();
    } catch (e) {
      debugPrint('Failed to get current version: $e');
      // Fallback - don't block update check
      currentVersion = '0.0.0';
    }

    try {
      // Get latest release info from GitHub API
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/$_owner/$_repo/releases/latest',
        ),
        headers: {'Accept': 'application/vnd.github+json'},
      );

      if (response.statusCode != 200) {
        // Silently fail - don't show toast, just debug
        debugPrint('Failed to check for updates: ${response.statusCode}');
        return;
      }

      final data = json.decode(response.body);
      final latestVersion = _extractVersion(
        data['tag_name'] ?? 'v$currentVersion',
      );
      final assets = data['assets'] as List? ?? [];

      // Check if this release is marked as mandatory
      final body = data['body']?.toString() ?? '';
      final isMandatory =
          body.contains('[MANDATORY]') ||
          body.contains('[إلزامي]') ||
          body.toLowerCase().contains('mandatory: true');

      // Find the arm64-v8a APK (smallest, for most phones)
      final apkAsset = assets.firstWhere(
        (a) => a['name']?.toString().contains('arm64-v8a-release.apk') ?? false,
        orElse: () => assets.isNotEmpty ? assets.first : null,
      );

      if (apkAsset == null) {
        debugPrint('No APK found in release');
        return;
      }

      final downloadUrl = apkAsset['browser_download_url'];
      final releaseNotes = body;

      // Check if update is needed
      if (!_isVersionNewer(latestVersion, currentVersion)) {
        debugPrint('App is up to date ($currentVersion)');
        return;
      }

      // Get the version user actually installed (not skipped)
      final installedVersion = prefs.getString(_installedVersionKey);

      // Reset skip if user upgraded manually since skipping
      final skippedVersion = prefs.getString(_skippedVersionKey);
      if (installedVersion != null &&
          skippedVersion != null &&
          skippedVersion == latestVersion &&
          _isVersionNewer(installedVersion, skippedVersion)) {
        // User has updated past the skipped version - clear skip
        await prefs.remove(_skippedVersionKey);
        debugPrint('Cleared skipped version after manual update');
      }

      // Check if user skipped this version
      if (skippedVersion == latestVersion && !isMandatory) {
        debugPrint('User skipped version $latestVersion');
        return;
      }

      // Update last check time
      await prefs.setInt(_lastCheckKey, now);

      // Show update dialog
      if (context.mounted) {
        await _showUpdateDialog(
          context,
          latestVersion,
          downloadUrl,
          releaseNotes,
          isMandatory: isMandatory,
        );
      }
    } catch (e) {
      // Silently fail - don't bother user with network issues
      debugPrint('Update check failed: $e');
    }
  }

  /// Show a toast notification (kept for future use)
  // ignore: unused_element
  static void _showToast(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Extract version from tag (e.g., "v1.0.0" -> "1.0.0")
  static String _extractVersion(String tag) {
    return tag.replaceFirst(RegExp(r'^v'), '').trim();
  }

  /// Compare versions: returns true if newVersion > currentVersion
  static bool _isVersionNewer(String newVersion, String currentVersion) {
    final newParts = newVersion
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final currentParts = currentVersion
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    for (int i = 0; i < 3; i++) {
      final newVal = i < newParts.length ? newParts[i] : 0;
      final currentVal = i < currentParts.length ? currentParts[i] : 0;

      if (newVal > currentVal) return true;
      if (newVal < currentVal) return false;
    }
    return false;
  }

  /// Show the update dialog with 3 options
  static Future<void> _showUpdateDialog(
    BuildContext context,
    String latestVersion,
    String downloadUrl,
    String releaseNotes, {
    bool isMandatory = false,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: !isMandatory, // Force update if mandatory
      builder: (ctx) => _UpdateDialog(
        version: latestVersion,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes,
        isMandatory: isMandatory,
      ),
    );
  }

  /// Mark current version as installed (call after successful update)
  static Future<void> markAsInstalled(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_installedVersionKey, version);
  }

  /// Skip this version
  static Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skippedVersionKey, version);
  }

  /// Reset skipped version (for testing)
  static Future<void> resetSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skippedVersionKey);
  }

  /// Force reset last check time (for testing)
  static Future<void> forceCheckNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, 0);
  }
}

/// Update dialog widget with 3 buttons
class _UpdateDialog extends StatefulWidget {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final bool isMandatory;

  const _UpdateDialog({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    this.isMandatory = false,
  });

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0;
  String _status = '';
  String? _error;

  @override
  Widget build(BuildContext context) {
    if (_isDownloading) {
      return AlertDialog(
        title: const Text('جاري التحديث...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 16),
            Text(_status, textAlign: TextAlign.center),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.isMandatory ? Icons.warning_amber : Icons.system_update,
            color: widget.isMandatory ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.isMandatory ? 'تحديث إلزامي!' : 'يتوفر تحديث جديد',
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإصدار الجديد: ${widget.version}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (widget.releaseNotes.isNotEmpty) ...[
            const Text(
              'ملاحظات الإصدار:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 100),
              child: SingleChildScrollView(
                child: Text(
                  widget.releaseNotes
                      .replaceAll(RegExp(r'\[MANDATORY\]'), '')
                      .replaceAll(RegExp(r'\[إلزامي\]'), '')
                      .trim(),
                  style: const TextStyle(fontSize: 12),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'التحديث الذكي: سيتم تحميل إصدار محسّن (أصغر حجماً)',
                    style: TextStyle(fontSize: 11, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          if (widget.isMandatory) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'هذا التحديث إلزامي لإصلاح مشكلة أمنية',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        // Remind me later
        if (!widget.isMandatory)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ذكرني لاحقاً'),
          ),
        // Skip this update
        if (!widget.isMandatory)
          TextButton(
            onPressed: () async {
              await UpdateService.skipVersion(widget.version);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('تخطي هذه المرة'),
          ),
        // Update now
        ElevatedButton(
          onPressed: _startDownload,
          child: Text(widget.isMandatory ? 'تحديث الآن' : 'تحديث'),
        ),
      ],
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _status = 'جاري التحميل...';
      _error = null;
    });

    try {
      await AppInstallerPlus().downloadAndInstallApk(
        downloadFileUrl: widget.downloadUrl,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _status = 'جاري التحميل: ${(progress * 100).toStringAsFixed(0)}%';
            });
          }
        },
        onDownloadedSize: (size) {
          debugPrint('Downloaded: $size');
        },
        onTotalSize: (size) {
          debugPrint('Total: $size');
        },
        onSpeed: (speed) {
          debugPrint('Speed: $speed');
        },
        onTimeLeft: (eta) {
          debugPrint('ETA: $eta');
        },
      );

      // Mark as installed after successful download
      await UpdateService.markAsInstalled(widget.version);

      if (mounted) {
        setState(() => _status = 'جاري التثبيت...');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل التحميل: $e';
          _status = 'حدث خطأ';
        });
      }
    }
  }
}
