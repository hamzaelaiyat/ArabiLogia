import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/core/models/grade_metadata.dart';

void main() {
  group('normalizeGradeIds', () {
    test('sorts and de-duplicates a multi-grade selection', () {
      expect(GradeMetadata.normalizeGradeIds([3, 1, 3, 10]), [1, 3, 10]);
    });

    test('collapses to the all-grades sentinel when 0 is present', () {
      expect(GradeMetadata.normalizeGradeIds([2, 0, 11]), [0]);
    });

    test('drops unknown ids', () {
      expect(GradeMetadata.normalizeGradeIds([1, 99, 7]), [1]);
    });

    test('keeps every real grade when all six are selected', () {
      expect(GradeMetadata.normalizeGradeIds([12, 10, 3, 1, 11, 2]), [
        1,
        2,
        3,
        10,
        11,
        12,
      ]);
    });
  });

  group('primaryGradeId', () {
    test('returns the lowest selected id', () {
      expect(GradeMetadata.primaryGradeId([10, 1, 3]), 1);
    });

    test('returns 0 when shared with every grade', () {
      expect(GradeMetadata.primaryGradeId([0]), 0);
    });

    test('falls back to the default grade when nothing is selected', () {
      expect(
        GradeMetadata.primaryGradeId(const []),
        GradeMetadata.defaultGradeId,
      );
    });
  });

  group('isVisibleToGrade', () {
    test('matches any selected grade', () {
      final shared = [1, 10];
      expect(GradeMetadata.isVisibleToGrade(shared, 1), isTrue);
      expect(GradeMetadata.isVisibleToGrade(shared, 10), isTrue);
      expect(GradeMetadata.isVisibleToGrade(shared, 2), isFalse);
      expect(GradeMetadata.isVisibleToGrade(shared, 11), isFalse);
    });

    test('the all-grades sentinel matches everyone', () {
      for (final grade in [1, 2, 3, 10, 11, 12]) {
        expect(
          GradeMetadata.isVisibleToGrade([0], grade),
          isTrue,
          reason: 'grade $grade should see an all-grades lecture',
        );
      }
    });

    test('an empty selection matches nobody', () {
      expect(GradeMetadata.isVisibleToGrade(const [], 1), isFalse);
    });
  });

  group('offline cache codec', () {
    test('round-trips a multi-grade selection', () {
      final csv = GradeMetadata.encodeGradeIdsCsv([10, 1, 3]);
      expect(csv, '1,3,10');
      expect(GradeMetadata.decodeGradeIdsCsv(csv, legacyGrade: 99), [1, 3, 10]);
    });

    test('encodes the all-grades sentinel', () {
      expect(GradeMetadata.encodeGradeIdsCsv([2, 0]), '0');
    });

    test('falls back to the legacy scalar column when empty', () {
      expect(GradeMetadata.decodeGradeIdsCsv('', legacyGrade: 3), [3]);
    });

    test('keeps a cached all-grades exam shared after decoding', () {
      final ids = GradeMetadata.decodeGradeIdsCsv('0', legacyGrade: 3);
      expect(GradeMetadata.isVisibleToGrade(ids, 12), isTrue);
    });
  });

  group('parseGradeIds', () {
    test('reads a Postgres integer array', () {
      expect(GradeMetadata.parseGradeIds([12, 1], legacyGrade: 1), [1, 12]);
    });

    test('coerces string entries defensively', () {
      expect(GradeMetadata.parseGradeIds(['10', '2']), [2, 10]);
    });

    test('falls back to the legacy grade when the array is empty', () {
      expect(GradeMetadata.parseGradeIds(const [], legacyGrade: 11), [11]);
    });

    test('falls back when the column is missing entirely', () {
      expect(GradeMetadata.parseGradeIds(null, legacyGrade: 2), [2]);
    });
  });
}
