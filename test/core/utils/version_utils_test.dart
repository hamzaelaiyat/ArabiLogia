import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/core/utils/version_utils.dart';

void main() {
  group('VersionUtils.extractVersion', () {
    test('keeps the numeric preview suffix', () {
      expect(VersionUtils.extractVersion('v26.9.26-03'), '26.9.26-03');
      expect(VersionUtils.extractVersion('26.9.26-02'), '26.9.26-02');
    });

    test('keeps a plain version and drops the leading v', () {
      expect(VersionUtils.extractVersion('v26.9.26'), '26.9.26');
    });

    test('drops build metadata and trailing letters', () {
      expect(VersionUtils.extractVersion('v26.9.26-03+5'), '26.9.26-03');
      expect(VersionUtils.extractVersion('v2.7.8b'), '2.7.8');
    });

    test('returns empty for non-version tags', () {
      expect(VersionUtils.extractVersion('latest'), '');
    });
  });

  group('VersionUtils.isVersionNewer', () {
    test('orders preview builds of the same core version', () {
      // The regression that stopped v26.9.26-02 users from seeing -03.
      expect(VersionUtils.isVersionNewer('26.9.26-03', '26.9.26-02'), isTrue);
      expect(VersionUtils.isVersionNewer('26.9.26-02', '26.9.26-03'), isFalse);
      expect(VersionUtils.isVersionNewer('26.9.26-10', '26.9.26-09'), isTrue);
    });

    test('a final release supersedes its previews', () {
      expect(VersionUtils.isVersionNewer('26.9.26', '26.9.26-03'), isTrue);
      expect(VersionUtils.isVersionNewer('26.9.26-03', '26.9.26'), isFalse);
    });

    test('compares the core version first', () {
      expect(VersionUtils.isVersionNewer('26.9.26', '26.9.25'), isTrue);
      expect(VersionUtils.isVersionNewer('26.9.26-01', '26.9.25'), isTrue);
      expect(VersionUtils.isVersionNewer('27.0.0', '26.9.26-99'), isTrue);
      expect(VersionUtils.isVersionNewer('26.9.25', '26.9.26'), isFalse);
    });

    test('equal versions are not newer', () {
      expect(VersionUtils.isVersionNewer('26.9.26-03', '26.9.26-03'), isFalse);
      expect(VersionUtils.isVersionNewer('26.9.26', '26.9.26'), isFalse);
    });

    test('tolerates v prefixes and build metadata', () {
      expect(VersionUtils.isVersionNewer('v26.9.26-03', '26.9.26-02'), isTrue);
    });
  });

  group('VersionUtils.cleanReleaseNotes', () {
    test('removes mandatory flags', () {
      const raw = '[MANDATORY] [إلزامي] mandatory: true\n## شاشة تحميل جديدة';
      final cleaned = VersionUtils.cleanReleaseNotes(raw);
      expect(cleaned, equals('## شاشة تحميل جديدة'));
    });

    test('strips top H1 header when no hidden marker is present', () {
      const raw = '''
# الجديد في عربلوجيا v26.9.07
## شاشة تحميل جديدة
- شاشة تحميل عملية تعرض شعار «عربلوجيا»
- تحميل الفئات مسبقاً
''';
      final cleaned = VersionUtils.cleanReleaseNotes(raw);
      expect(cleaned.startsWith('# الجديد'), isFalse);
      expect(cleaned.startsWith('## شاشة تحميل جديدة'), isTrue);
    });

    test('strips everything before hidden marker tag when present', () {
      const raw = '''
# هذا العنوان والمقدمة قد يحتوي على أصل النص
هذا كلام تعريفي لن يظهر في الشاشة الرئيسية
<!-- start -->
## شاشة تحميل جديدة
- شاشة تحميل عملية تعرض شعار «عربلوجيا»
''';
      final cleaned = VersionUtils.cleanReleaseNotes(raw);
      expect(cleaned.startsWith('## شاشة تحميل جديدة'), isTrue);
      expect(cleaned.contains('هذا كلام تعريفي'), isFalse);
    });
  });
}
