import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabilogia/core/utils/version_utils.dart';

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

/// Why a check failed, so the UI can explain itself instead of failing silently.
enum UpdateCheckFailure {
  none,
  network,
  rateLimited,
  serverError,
  malformedResponse,
  noAsset,
}

/// Detailed outcome of a check, surfaced in the settings screen so a failed
/// check is explainable on-device instead of vanishing without a trace.
class UpdateCheckReport {
  final UpdateCheckResult result;
  final UpdateCheckFailure failure;
  final String? latestTag;
  final String? latestVersion;
  final String? currentVersion;
  final String? assetName;
  final int? httpStatus;
  final String? detail;

  const UpdateCheckReport({
    required this.result,
    this.failure = UpdateCheckFailure.none,
    this.latestTag,
    this.latestVersion,
    this.currentVersion,
    this.assetName,
    this.httpStatus,
    this.detail,
  });

  bool get hasUpdate => result == UpdateCheckResult.updateAvailable;
}

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

  /// Last outcome of a check, retained so the settings screen can explain a
  /// failure the user actually experienced.
  static UpdateCheckReport? _lastReport;

  static UpdateCheckReport? get lastReport => _lastReport;

  /// True when an update was detected but no screen was listening yet. The
  /// boot sequence can emit before the navigator exists, so the pending update
  /// is kept instead of dropped.
  static bool get hasPendingUpdate => _currentUpdate != null;

  static void _log(String message) {
    debugPrint('[UpdateService] $message');
  }

  /// Test seams. The updater used to fail silently with no way to exercise it,
  /// so both the network call and the installed version are injectable.
  @visibleForTesting
  static Future<http.Response> Function(Uri uri)? httpFetchOverride;

  @visibleForTesting
  static Future<String> Function()? currentVersionOverride;

  /// Get current app version from package_info_plus
  static Future<String> getCurrentVersion() async {
    final override = currentVersionOverride;
    if (override != null) return override();
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Check for updates in background - doesn't block UI
  /// Emits update to stream if available
  ///
  /// [force] bypasses the cooldown and is used by the manual
  /// "check for updates" action, so a user who suspects a missed update is
  /// never stuck waiting for a timer they cannot see or reset.
  static Future<UpdateCheckReport> checkForUpdatesInBackground({
    bool force = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (!force && now - lastCheck < _minCheckInterval.inMilliseconds) {
      _log('skipped: cooldown active, retrying in '
          '${_minCheckInterval.inMilliseconds - (now - lastCheck)}ms');
      return _lastReport ??
          const UpdateCheckReport(result: UpdateCheckResult.noUpdate);
    }

    String currentVersion;
    try {
      currentVersion = await getCurrentVersion();
    } catch (e) {
      _log('could not read installed version: $e');
      currentVersion = '0.0.0';
    }
    _log('installed version: $currentVersion');

    http.Response response;
    try {
      // The repository is public, so the releases API works unauthenticated.
      // Never ship a GitHub token in the client bundle: .env is bundled as an
      // asset, so any key inside it is publicly readable from the APK and the
      // web build.
      const headers = {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'ArabiLogia-Update-Checker',
        'X-GitHub-Api-Version': '2022-11-28',
      };

      final fetch = httpFetchOverride;
      response = await (fetch != null
              ? fetch(Uri.parse(
                  'https://api.github.com/repos/$_owner/$_repo/releases/latest',
                ))
              : http
                  .get(
                    Uri.parse(
                      'https://api.github.com/repos/$_owner/$_repo/releases/latest',
                    ),
                    headers: headers,
                  )
                  .timeout(const Duration(seconds: 30)));

    } catch (e, st) {
      // A failed attempt must not consume the cooldown, otherwise one flaky
      // network moment silences update checks for the next hour.
      _log('network failure: $e\n$st');
      return _fail(
        UpdateCheckFailure.network,
        currentVersion: currentVersion,
        detail: e.toString(),
      );
    }

    if (response.statusCode != 200) {
      final remaining = response.headers['x-ratelimit-remaining'];
      final isRateLimited = response.statusCode == 403 ||
          response.statusCode == 429 ||
          (remaining != null && remaining == '0');
      _log('HTTP ${response.statusCode}'
          '${isRateLimited ? ' (rate limited, remaining=$remaining)' : ''}');
      return _fail(
        isRateLimited
            ? UpdateCheckFailure.rateLimited
            : (response.statusCode >= 500
                ? UpdateCheckFailure.serverError
                : UpdateCheckFailure.malformedResponse),
        currentVersion: currentVersion,
        httpStatus: response.statusCode,
        detail: isRateLimited ? 'rate limit reached' : null,
      );
    }

    Map<String, dynamic> data;
    try {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('release payload is not a JSON object');
      }
      data = decoded;
    } catch (e, st) {
      _log('could not read release payload: $e\n$st');
      return _fail(
        UpdateCheckFailure.malformedResponse,
        currentVersion: currentVersion,
        httpStatus: response.statusCode,
        detail: e.toString(),
      );
    }

    final tag = data['tag_name']?.toString() ?? '';
    final latestVersion = VersionUtils.extractVersion(
      tag.isEmpty ? 'v$currentVersion' : tag,
    );
    _log('release tag: "${data['name']}" ($tag) -> parsed version: $latestVersion');

    final assets = data['assets'] as List? ?? const [];
    final body = data['body']?.toString() ?? '';
    final isMandatory = body.contains('[MANDATORY]') ||
        body.contains('[إلزامي]') ||
        body.toLowerCase().contains('mandatory: true');

    final targetAsset = _findBestApk(assets, Platform.operatingSystem);
    if (targetAsset == null) {
      _log('no matching asset for ${Platform.operatingSystem} '
          'among ${assets.length} asset(s)');
      return _fail(
        UpdateCheckFailure.noAsset,
        currentVersion: currentVersion,
        latestTag: tag,
        latestVersion: latestVersion,
        httpStatus: response.statusCode,
        detail: 'no ${Platform.operatingSystem} asset in release',
      );
    }
    final assetName = targetAsset['name']?.toString() ?? '';
    _log('selected asset: $assetName');

    // Check if update is needed
    if (!VersionUtils.isVersionNewer(latestVersion, currentVersion)) {
      _log('up to date: $latestVersion is not newer than $currentVersion');
      _updateStreamController.add(null);
      final report = UpdateCheckReport(
        result: UpdateCheckResult.noUpdate,
        latestTag: tag,
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        assetName: assetName,
        httpStatus: response.statusCode,
      );
      _lastReport = report;
      await prefs.setInt(_lastCheckKey, now);
      return report;
    }

    // Check if user skipped this version
    final skippedVersion = prefs.getString(_skippedVersionKey);
    if (skippedVersion == latestVersion && !isMandatory) {
      _log('version $latestVersion was skipped by the user');
      _updateStreamController.add(null);
      final report = UpdateCheckReport(
        result: UpdateCheckResult.noUpdate,
        latestTag: tag,
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        assetName: assetName,
        httpStatus: response.statusCode,
      );
      _lastReport = report;
      await prefs.setInt(_lastCheckKey, now);
      return report;
    }

    final update = AppUpdate(
      version: latestVersion,
      downloadUrl: targetAsset['browser_download_url'],
      releaseNotes: VersionUtils.cleanReleaseNotes(body),
      isMandatory: isMandatory,
      fileSize: targetAsset['size'] ?? 0,
      fileName: assetName.isEmpty ? 'app.apk' : assetName,
    );

    _currentUpdate = update;
    _log('update available: ${update.version} -> ${update.fileName} '
        '(${update.fileSize} bytes)');

    final report = UpdateCheckReport(
      result: UpdateCheckResult.updateAvailable,
      latestTag: tag,
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      assetName: assetName,
      httpStatus: response.statusCode,
    );
    _lastReport = report;
    await prefs.setInt(_lastCheckKey, now);

    // Emit update to stream
    _updateStreamController.add(update);
    return report;
  }

  static UpdateCheckReport _fail(
    UpdateCheckFailure failure, {
    String? currentVersion,
    int? httpStatus,
    String? latestTag,
    String? latestVersion,
    String? detail,
  }) {
    _updateStreamController.add(null);
    final report = UpdateCheckReport(
      result: UpdateCheckResult.error,
      failure: failure,
      currentVersion: currentVersion,
      httpStatus: httpStatus,
      latestTag: latestTag,
      latestVersion: latestVersion,
      detail: detail,
    );
    _lastReport = report;
    return report;
  }

  /// The detected update, if one is waiting to be shown. Lets the UI pick up an
  /// update that was detected before its listener was mounted.
  static AppUpdate? takePendingUpdate() {
    final update = _currentUpdate;
    _currentUpdate = null;
    return update;
  }


  /// Platform-specific APK selection
  static Map<String, dynamic>? _findBestApk(List assets, String os) {
    // Try to find platform-specific APK first
    if (os == 'android') {
      try {
        return assets.firstWhere(
          (a) => a['name']?.toString().contains('arm64-v8a') ?? false,
        );
      } catch (e) {
        debugPrint('No arm64-v8a APK found, falling back: $e');
        try {
          return assets.firstWhere(
            (a) => a['name']?.toString().contains('arm64') ?? false,
          );
        } catch (e) {
          debugPrint('No arm64 APK found, using first asset: $e');
          return assets.isNotEmpty ? assets.first : null;
        }
      }
    } else if (os == 'windows') {
      try {
        return assets.firstWhere(
          (a) => a['name']?.toString().endsWith('.exe') ?? false,
        );
      } catch (e) {
        debugPrint('No Windows .exe asset found, using first: $e');
        return assets.isNotEmpty ? assets.first : null;
      }
    } else if (os == 'linux') {
      // Releases ship a .tar.xz bundle, not AppImage/deb.
      for (final a in assets) {
        final name = a['name']?.toString() ?? '';
        if (name.endsWith('.tar.xz') ||
            name.endsWith('.AppImage') ||
            name.endsWith('.deb')) {
          return a;
        }
      }
      debugPrint('No Linux bundle found among ${assets.length} asset(s)');
      return null;
    }
    if (os == 'android' || os == 'ios') {
      debugPrint('No in-app update asset for $os');
      return null;
    }
    return assets.isNotEmpty ? assets.first : null;
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

  /// Dismiss What's New dialog after user views it
  static Future<void> dismissWhatsNew() async {
    final prefs = await SharedPreferences.getInstance();
    final currentVersion = await getCurrentVersion();
    await prefs.setString(_installedVersionKey, currentVersion);
    await prefs.remove('whats_new_notes');
  }
}
