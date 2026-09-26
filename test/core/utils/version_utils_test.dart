import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/core/utils/version_utils.dart';

void main() {
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
