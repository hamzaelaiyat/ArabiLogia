import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/features/gate/models/gate_status.dart';

import '../../../helpers/test_helper.dart';

void main() {
  group('GateStatus.fromJson', () {
    test('parses a fully populated payload', () {
      final status = GateStatus.fromJson({
        'grade': 2,
        'needs_unlock': false,
        'unlocked': true,
        'rotated': false,
        'has_passcode': true,
        'expires_at': '2026-12-31T23:59:59Z',
      });

      expect(status.grade, 2);
      expect(status.needsUnlock, isFalse);
      expect(status.unlocked, isTrue);
      expect(status.rotated, isFalse);
      expect(status.hasPasscode, isTrue);
      expect(status.expiresAt, isNotNull);
      expect(status.expiresAt!.toUtc(), DateTime.utc(2026, 12, 31, 23, 59, 59));
    });

    test('treats missing fields as safe defaults', () {
      final status = GateStatus.fromJson({'grade': 1});

      expect(status.grade, 1);
      expect(status.needsUnlock, isTrue);
      expect(status.unlocked, isFalse);
      expect(status.rotated, isFalse);
      expect(status.hasPasscode, isFalse);
      expect(status.expiresAt, isNull);
    });
  });

  group('GateAdminStatus.fromJson', () {
    test('parses a populated payload', () {
      final status = GateAdminStatus.fromJson({
        'grade': 2,
        'has_passcode': true,
        'updated_at': '2026-08-05T01:20:50.784763+00:00',
        'expires_at': '2026-12-31T23:59:59Z',
        'exam_ids': <dynamic>['e1', 'e2'],
      });

      expect(status.grade, 2);
      expect(status.hasPasscode, isTrue);
      expect(status.updatedAt, isNotNull);
      expect(status.expiresAt, isNotNull);
      expect(status.examIds, ['e1', 'e2']);
    });

    test('treats missing fields as safe defaults', () {
      final status = GateAdminStatus.fromJson({'grade': 1});

      expect(status.grade, 1);
      expect(status.hasPasscode, isFalse);
      expect(status.updatedAt, isNull);
      expect(status.expiresAt, isNull);
      expect(status.examIds, isEmpty);
    });
  });

  group('GateExamList.fromJson', () {
    test('parses an empty unlocked list', () {
      final list = GateExamList.fromJson({
        'unlocked': false,
        'grade': 2,
        'items': <dynamic>[],
      });

      expect(list.unlocked, isFalse);
      expect(list.grade, 2);
      expect(list.items, isEmpty);
    });

    test('parses a populated unlocked list', () {
      final list = GateExamList.fromJson({
        'unlocked': true,
        'grade': 3,
        'items': [
          {
            'id': 'g1',
            'title': 'Final',
            'subject_id': 'nahw',
            'duration_minutes': 30,
            'sort_order': 2,
          },
        ],
      });

      expect(list.unlocked, isTrue);
      expect(list.items, hasLength(1));
      final item = list.items.single;
      expect(item.id, 'g1');
      expect(item.title, 'Final');
      expect(item.subjectId, 'nahw');
      expect(item.durationMinutes, 30);
      expect(item.sortOrder, 2);
    });
  });
}
