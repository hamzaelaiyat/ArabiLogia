import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/features/dashboard/leaderboard/widgets/leaderboard_helpers.dart';

void main() {
  group('getGradeName', () {
    test('returns correct Arabic grade names', () {
      expect(getGradeName(10), 'الأولى باكالوريا');
      expect(getGradeName(11), 'الثانية ثانوي');
      expect(getGradeName(12), 'الثالثة ثانوي');
    });

    test('returns default for unknown grade', () {
      expect(getGradeName(0), 'كل الصفوف');
      expect(getGradeName(99), 'كل الصفوف');
    });
  });

  group('getAvatar', () {
    test('returns first character for full name with spaces', () {
      expect(getAvatar('كريم سيد'), 'ك');
      expect(getAvatar('أحمد علي'), 'أ');
      expect(getAvatar('محمد'), 'م');
    });

    test('returns first character for single name', () {
      expect(getAvatar('يوسف'), 'ي');
    });

    test('returns ط for empty name', () {
      expect(getAvatar(''), 'ط');
      expect(getAvatar('   '), 'ط');
    });

    test('does not produce two-character initials', () {
      final result = getAvatar('كريم سيد');
      expect(result.length, 1);
      expect(result, isNot('كس')); // vulgar word safeguard
    });

    test('handles trimmed whitespace', () {
      expect(getAvatar('  علي  محمد  '), 'ع');
    });
  });

  group('getGradeValueFromLabel', () {
    test('parses grade labels correctly', () {
      expect(getGradeValueFromLabel('الأولى باكالوريا'), 10);
      expect(getGradeValueFromLabel('الثانية ثانوي'), 11);
      expect(getGradeValueFromLabel('الثالثة ثانوي'), 12);
    });

    test('returns 0 for unknown label', () {
      expect(getGradeValueFromLabel('غير معروف'), 0);
    });
  });
}
