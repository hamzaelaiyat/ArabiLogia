class VersionUtils {
  /// Keeps the core version and any numeric preview suffix, e.g.
  /// `v26.9.26-03` -> `26.9.26-03`. Build metadata (`+5`) and trailing letters
  /// are dropped. The preview suffix must survive: it is what orders
  /// `26.9.26-02` below `26.9.26-03`.
  static String extractVersion(String tag) {
    final value = tag.trim().replaceFirst(RegExp(r'^v'), '');
    final match = RegExp(r'^\d+(?:\.\d+){0,2}(?:-\d+)?').firstMatch(value);
    return match?.group(0) ?? '';
  }

  static ({List<int> core, int? suffix}) _parse(String raw) {
    final value = extractVersion(raw);
    final parts = value.split('-');
    final segments = parts.first.split('.');
    int at(int i) => i < segments.length ? (int.tryParse(segments[i]) ?? 0) : 0;
    return (
      core: [at(0), at(1), at(2)],
      suffix: parts.length > 1 ? int.tryParse(parts[1]) : null,
    );
  }

  static bool isVersionNewer(String newVersion, String currentVersion) {
    final next = _parse(newVersion);
    final current = _parse(currentVersion);

    for (var i = 0; i < 3; i++) {
      if (next.core[i] > current.core[i]) return true;
      if (next.core[i] < current.core[i]) return false;
    }

    // Same core version. A build with no preview suffix is the final release,
    // so it supersedes every preview of that same core version.
    final nextSuffix = next.suffix;
    final currentSuffix = current.suffix;
    if (nextSuffix == null && currentSuffix == null) return false;
    if (nextSuffix == null) return true;
    if (currentSuffix == null) return false;
    return nextSuffix > currentSuffix;
  }

  static String cleanReleaseNotes(String body) {
    String notes = body
        .replaceAll(RegExp(r'\[MANDATORY\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[إلزامي\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'mandatory:\s*true', caseSensitive: false), '')
        .trim();

    // 1. Check for hidden marker comments (e.g., <!-- start --> or <!-- notes -->)
    final markerRegex = RegExp(
      r'<!--\s*(start|notes|release-notes|summary-start|content-start)\s*-->',
      caseSensitive: false,
    );
    final match = markerRegex.firstMatch(notes);
    if (match != null) {
      return notes.substring(match.end).trim();
    }

    // 2. Fallback: Strip top H1 heading (# ...) for older release notes
    notes = notes.replaceFirst(RegExp(r'^#\s+[^\n]*\n?'), '').trim();

    return notes;
  }
}
