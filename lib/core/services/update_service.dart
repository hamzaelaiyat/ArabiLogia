import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents an available update
class AppUpdate {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final bool isMandatory;
  final int fileSize;
  final String fileName;

  AppUpdate({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isMandatory,
    required this.fileSize,
    required this.fileName,
  });
}

/// Update check result
enum UpdateCheckResult { noUpdate, updateAvailable, error }

/// Service for handling app updates from GitHub Releases
/// Supports background checking and cross-platform updates
class UpdateService {
  // GitHub repository configuration
  static const String _owner = 'hamzaelaiyat';
  static const String _repo = 'ArabiLogia';

  // Storage keys
  static const String _skippedVersionKey = 'skipped_update_version';
  static const String _lastCheckKey = 'last_update_check';
  static const String _installedVersionKey = 'installed_version';
  static const String _lastSkippedKey = 'last_skipped_time';

  // Minimum time between update checks (1 hour for background)
  static const Duration _minCheckInterval = Duration(hours: 1);

  // Stream controller for update events
  static final StreamController<AppUpdate?> _updateStreamController =
      StreamController<AppUpdate?>.broadcast();

  static Stream<AppUpdate?> get updateStream => _updateStreamController.stream;

  static AppUpdate? _currentUpdate;

  /// Get current app version from package_info_plus
  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Check for updates in background - doesn't block UI
  /// Emits update to stream if available
  static Future<void> checkForUpdatesInBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastCheck < _minCheckInterval.inMilliseconds) {
      debugPrint('UpdateService: Skipping check - within cooldown');
      return;
    }

    String currentVersion;
    try {
      currentVersion = await getCurrentVersion();
    } catch (e) {
      currentVersion = '0.0.0';
    }

    try {
      // Build headers with optional GitHub token
      final githubToken = dotenv.env['GITHUB_TOKEN'];
      final headers = {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'ArabiLogia-Update-Checker',
        'X-GitHub-Api-Version': '2022-11-28',
      };
      if (githubToken != null && githubToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $githubToken';
      }

      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/$_owner/$_repo/releases/latest',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        debugPrint('UpdateService: Failed to check - ${response.statusCode}');
        return;
      }

      final data = json.decode(response.body);
      final latestVersion = _extractVersion(
        data['tag_name'] ?? 'v$currentVersion',
      );
      final assets = data['assets'] as List? ?? [];

      // Parse release notes and check for mandatory
      final body = data['body']?.toString() ?? '';
      final isMandatory =
          body.contains('[MANDATORY]') ||
          body.contains('[إلزامي]') ||
          body.toLowerCase().contains('mandatory: true');

      // Find appropriate APK for current platform
      final targetAsset = _findBestApk(assets, Platform.operatingSystem);

      if (targetAsset == null) {
        debugPrint('UpdateService: No suitable APK found');
        return;
      }

      // Check if update is needed
      if (!_isVersionNewer(latestVersion, currentVersion)) {
        debugPrint('UpdateService: App is up to date');
        _updateStreamController.add(null);
        return;
      }

      // Check if user skipped this version
      final skippedVersion = prefs.getString(_skippedVersionKey);
      if (skippedVersion == latestVersion && !isMandatory) {
        debugPrint('UpdateService: User skipped version $latestVersion');
        _updateStreamController.add(null);
        return;
      }

      // Create update object
      final update = AppUpdate(
        version: latestVersion,
        downloadUrl: targetAsset['browser_download_url'],
        releaseNotes: _cleanReleaseNotes(body),
        isMandatory: isMandatory,
        fileSize: targetAsset['size'] ?? 0,
        fileName: targetAsset['name'] ?? 'app.apk',
      );

      _currentUpdate = update;

      // Emit update to stream
      _updateStreamController.add(update);
      debugPrint('UpdateService: Found update ${update.version}');
    } catch (e) {
      debugPrint('UpdateService: Error checking for updates: $e');
      _updateStreamController.add(null);
    } finally {
      // Update last check time
      await prefs.setInt(_lastCheckKey, now);
    }
  }

  /// Platform-specific APK selection
  static Map<String, dynamic>? _findBestApk(List assets, String os) {
    // Try to find platform-specific APK first
    if (os == 'android') {
      try {
        return assets.firstWhere(
          (a) => a['name']?.toString().contains('arm64-v8a') ?? false,
        );
      } catch (_) {
        // Fall back to any APK with arm64
        try {
          return assets.firstWhere(
            (a) => a['name']?.toString().contains('arm64') ?? false,
          );
        } catch (_) {
          return assets.isNotEmpty ? assets.first : null;
        }
      }
    } else if (os == 'windows') {
      try {
        return assets.firstWhere(
          (a) => a['name']?.toString().endsWith('.exe') ?? false,
        );
      } catch (_) {
        return assets.isNotEmpty ? assets.first : null;
      }
    } else if (os == 'linux') {
      try {
        return assets.firstWhere((a) {
          final name = a['name']?.toString() ?? '';
          return name.endsWith('.AppImage') || name.endsWith('.deb');
        });
      } catch (_) {
        return assets.isNotEmpty ? assets.first : null;
      }
    }
    return assets.isNotEmpty ? assets.first : null;
  }

  /// Clean release notes
  static String _cleanReleaseNotes(String body) {
    return body
        .replaceAll(RegExp(r'\[MANDATORY\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[إلزامي\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'mandatory:\s*true', caseSensitive: false), '')
        .trim();
  }

  /// Extract version from tag
  static String _extractVersion(String tag) {
    String version = tag.replaceFirst(RegExp(r'^v'), '').trim();
    version = version.replaceAll(RegExp(r'[bba-zB-Z].*$'), '');
    return version;
  }

  /// Compare versions
  static bool _isVersionNewer(String newVersion, String currentVersion) {
    String cleanNew = newVersion.replaceAll(RegExp(r'[bba-zB-Z].*$'), '');
    String cleanCurrent = currentVersion.replaceAll(
      RegExp(r'[bba-zB-Z].*$'),
      '',
    );

    final newParts = cleanNew
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final currentParts = cleanCurrent
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

  /// Skip this version
  static Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skippedVersionKey, version);
    await prefs.setInt(_lastSkippedKey, DateTime.now().millisecondsSinceEpoch);
    _updateStreamController.add(null);
  }

  /// Remind later - reset cooldown
  static Future<void> remindLater() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, 0);
    _updateStreamController.add(null);
  }

  /// Get the current update
  static AppUpdate? get currentUpdate => _currentUpdate;

  /// Force check now (bypass cooldown)
  static Future<void> forceCheckNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, 0);
    await checkForUpdatesInBackground();
  }

  /// Check if should show What's New dialog
  static Future<bool> shouldShowWhatsNew() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getString(_installedVersionKey);
    final currentVersion = await getCurrentVersion();
    return lastUpdate != null && lastUpdate != currentVersion;
  }

  /// Get stored release notes for What's New dialog
  static Future<String> getWhatsNewNotes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('whats_new_notes') ?? '';
  }

  /// Store release notes when updating
  static Future<void> storeWhatsNewNotes(
    String version,
    String releaseNotes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_installedVersionKey, version);
    await prefs.setString('whats_new_notes', releaseNotes);
  }

  /// Mark version as installed
  static Future<void> markAsInstalled(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_installedVersionKey, version);
  }
}

/// Platform-specific update installer
class PlatformUpdateInstaller {
  static Future<void> installUpdate(AppUpdate update) async {
    if (Platform.isAndroid) {
      await _installAndroid(update);
    } else if (Platform.isWindows) {
      await _installWindows(update);
    } else if (Platform.isLinux) {
      await _installLinux(update);
    }
  }

  /// Android: Use DownloadManager and request unknown sources
  static Future<void> _installAndroid(AppUpdate update) async {
    // For now, we'll use a simpler approach with the system browser
    // A full implementation would use DownloadManager and PackageManager
    debugPrint('Android update: Starting download from ${update.downloadUrl}');

    // Note: Full Android implementation requires:
    // 1. DownloadManager API for background downloads
    // 2. REQUEST_INSTALL_PACKAGES permission (already added)
    // 3. PackageManager to install silently

    // For demonstration, we'll use the URL launcher approach
    // which opens the browser and lets user download
    throw UnimplementedError('Use UpdateConfirmPage for Android update flow');
  }

  /// Windows: Download and run installer
  static Future<void> _installWindows(AppUpdate update) async {
    debugPrint('Windows update: Downloading ${update.downloadUrl}');
    // Implementation would:
    // 1. Download the .exe to temp folder
    // 2. Run the installer with elevated privileges
    // 3. Restart app after update
    throw UnimplementedError('Use UpdateConfirmPage for Windows update flow');
  }

  /// Linux: Download and run installer/AppImage
  static Future<void> _installLinux(AppUpdate update) async {
    debugPrint('Linux update: Downloading ${update.downloadUrl}');
    // Implementation would:
    // 1. Download AppImage/deb
    // 2. Make executable and run
    throw UnimplementedError('Use UpdateConfirmPage for Linux update flow');
  }
}
