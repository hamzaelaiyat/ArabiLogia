class VersionUtils {
  static String extractVersion(String tag) {
    String version = tag.replaceFirst(RegExp(r'^v'), '').trim();
    version = version.replaceAll(RegExp(r'[^0-9.].*$'), '');
    return version;
  }

  static bool isVersionNewer(String newVersion, String currentVersion) {
    String cleanNew = newVersion.replaceAll(RegExp(r'[^0-9.].*$'), '');
    String cleanCurrent = currentVersion.replaceAll(
      RegExp(r'[^0-9.].*$'),
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

  static String cleanReleaseNotes(String body) {
    return body
        .replaceAll(RegExp(r'\[MANDATORY\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[إلزامي\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'mandatory:\s*true', caseSensitive: false), '')
        .trim();
  }
}
