import 'package:flutter/services.dart';

class AppVersion {
  static String? _cachedVersion;
  static String? _cachedBuildNumber;

  /// Get version from pubspec.yaml (cached after first call)
  static Future<String> getVersion() async {
    if (_cachedVersion != null) return _cachedVersion!;

    try {
      final pubspec = await rootBundle.loadString('pubspec.yaml');
      final lines = pubspec.split('\n');
      for (final line in lines) {
        if (line.trim().startsWith('version:')) {
          final versionString = line.split(':')[1].trim();
          // Format: "2.8.0-b+1" -> extract "2.8.0-b" (version) and "1" (build)
          final parts = versionString.split('+');
          _cachedVersion = parts[0].replaceAll('"', '').replaceAll("'", '');
          if (parts.length > 1) {
            _cachedBuildNumber = parts[1];
          }
          break;
        }
      }
    } catch (_) {
      _cachedVersion = '2.8.0-b';
      _cachedBuildNumber = '1';
    }

    return _cachedVersion!;
  }

  /// Get version synchronously (returns cached or fallback)
  static String get versionSync {
    return _cachedVersion ?? '2.8.0-b';
  }

  /// Get build number
  static String get buildNumberSync {
    return _cachedBuildNumber ?? '1';
  }

  /// Full version string for display
  static String get displayVersion {
    final v = versionSync;
    final b = buildNumberSync;
    return 'v$v+$b';
  }

  /// Preload version at app startup
  static Future<void> preload() async {
    await getVersion();
  }
}
