import 'dart:async';

import 'package:arabilogia/features/gate/repositories/gate_repository.dart';

import '../../../helpers/test_helper.dart';

class FakeRpcFilterBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  final Object? value;
  final Object? error;
  FakeRpcFilterBuilder(this.value) : error = null;
  FakeRpcFilterBuilder.error(this.error) : value = null;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(dynamic) onValue, {
    Function? onError,
  }) {
    if (error != null) {
      return Future<dynamic>.error(error!).then<U>(onValue, onError: onError);
    }
    return Future<dynamic>.value(value).then<U>(onValue, onError: onError);
  }
}

class FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  final List<Map<String, dynamic>> rows;
  final Object? error;
  final Map<String, dynamic> eqValues = {};
  FakeFilterBuilder(this.rows) : error = null;
  FakeFilterBuilder.error(this.error) : rows = const [];

  @override
  Future<U> then<U>(
    FutureOr<U> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) {
    if (error != null) {
      final completer = Completer<PostgrestList>()..completeError(error!);
      return completer.future.then<U>(onValue, onError: onError);
    }
    return Future<PostgrestList>.value(rows).then<U>(onValue, onError: onError);
  }

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    eqValues[column] = value;
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestList> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) =>
      this;

  @override
  PostgrestTransformBuilder<PostgrestList> limit(
    int count, {
    String? referencedTable,
  }) =>
      this;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) =>
      this;
}

void main() {
  late MockSupabaseService mockSupabase;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockSupabase = MockSupabaseService();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
  });

  group('GateRepository.status', () {
    test('parses the status payload', () async {
      when(() => mockSupabase.rpc(
            'gate_status',
            params: {'p_grade': 2},
          )).thenAnswer((_) => FakeRpcFilterBuilder({
                'grade': 2,
                'needs_unlock': true,
                'unlocked': false,
                'rotated': false,
                'has_passcode': true,
              }));

      final repo = GateRepository(supabaseService: mockSupabase);
      final status = await repo.status(2);

      expect(status.grade, 2);
      expect(status.needsUnlock, isTrue);
      expect(status.hasPasscode, isTrue);
    });
  });

  group('GateRepository.unlock', () {
    test('forwards the passcode to the RPC', () async {
      when(() => mockSupabase.rpc(
            'gate_unlock',
            params: {'p_grade': 2, 'p_code': 's3cret'},
          )).thenAnswer((_) => FakeRpcFilterBuilder({
                'grade': 2,
                'unlocked_at': '2026-08-03T12:00:00Z',
              }));

      final repo = GateRepository(supabaseService: mockSupabase);
      await repo.unlock(2, 's3cret');

      verify(() => mockSupabase.rpc(
            'gate_unlock',
            params: {'p_grade': 2, 'p_code': 's3cret'},
          )).called(1);
    });

    test('rethrows RPC errors so the UI can show them', () async {
      when(() => mockSupabase.rpc(
            'gate_unlock',
            params: any(named: 'params'),
          )).thenAnswer(
              (_) => FakeRpcFilterBuilder.error('كلمة المرور غير صحيحة'));

      final repo = GateRepository(supabaseService: mockSupabase);
      expect(
        () => repo.unlock(2, 'wrong'),
        throwsA(isA<String>().having((e) => e, 'value', contains('غير صحيحة'))),
      );
    });
  });

  group('GateRepository.listExams', () {
    test('parses the gated catalog', () async {
      when(() => mockSupabase.rpc('gate_list_exams')).thenAnswer(
          (_) => FakeRpcFilterBuilder({
                'unlocked': true,
                'grade': 2,
                'items': [
                  {
                    'id': 'g1',
                    'title': 'Final',
                    'subject_id': 'nahw',
                    'duration_minutes': 30,
                    'sort_order': 1,
                  },
                ],
              }));

      final repo = GateRepository(supabaseService: mockSupabase);
      final list = await repo.listExams();

      expect(list.unlocked, isTrue);
      expect(list.grade, 2);
      expect(list.items.single.id, 'g1');
    });
  });

  group('GateRepository.adminStatus', () {
    test('parses the admin status payload', () async {
      when(() => mockSupabase.rpc(
            'gate_admin_status',
            params: {'p_grade': 2},
          )).thenAnswer((_) => FakeRpcFilterBuilder({
                'grade': 2,
                'has_passcode': true,
                'updated_at': '2026-08-05T01:20:50Z',
                'expires_at': '2026-12-31T23:59:59Z',
                'exam_ids': <dynamic>['e1', 'e2'],
              }));

      final repo = GateRepository(supabaseService: mockSupabase);
      final status = await repo.adminStatus(2);

      expect(status.grade, 2);
      expect(status.hasPasscode, isTrue);
      expect(status.examIds, ['e1', 'e2']);
    });
  });

  group('GateRepository.setPasscode', () {
    test('forwards code to gate_set_passcode RPC', () async {
      when(() => mockSupabase.rpc(
            'gate_set_passcode',
            params: {
              'p_grade': 2,
              'p_code': 'newcode123',
              'p_expires_at': null,
            },
          )).thenAnswer((_) => FakeRpcFilterBuilder({
                'grade': 2,
                'updated_at': '2026-08-05T02:00:00Z',
                'expires_at': null,
              }));

      final repo = GateRepository(supabaseService: mockSupabase);
      await repo.setPasscode(2, 'newcode123');

      verify(() => mockSupabase.rpc(
            'gate_set_passcode',
            params: {
              'p_grade': 2,
              'p_code': 'newcode123',
              'p_expires_at': null,
            },
          )).called(1);
    });
  });

  group('GateRepository.setExams', () {
    test('forwards exam ids to gate_set_exams RPC', () async {
      when(() => mockSupabase.rpc(
            'gate_set_exams',
            params: {
              'p_grade': 2,
              'p_exam_ids': ['e1', 'e3'],
            },
          )).thenAnswer((_) => FakeRpcFilterBuilder(null));

      final repo = GateRepository(supabaseService: mockSupabase);
      await repo.setExams(2, ['e1', 'e3']);

      verify(() => mockSupabase.rpc(
            'gate_set_exams',
            params: {
              'p_grade': 2,
              'p_exam_ids': ['e1', 'e3'],
            },
          )).called(1);
    });
  });

  group('GateRepository.listAllExams', () {
    test('queries exams table and orders by created_at desc', () async {
      final exams = [
        {'id': 'e1', 'title': 'Exam 1', 'subject_id': 'nahw', 'grade': 2},
        {'id': 'e2', 'title': 'Exam 2', 'subject_id': 'sarf', 'grade': 3},
      ];
      final filter = FakeFilterBuilder(exams);
      when(() => mockSupabase.from('exams'))
          .thenAnswer((_) => FakeQueryBuilder(onSelect: () => filter));

      final repo = GateRepository(supabaseService: mockSupabase);
      final result = await repo.listAllExams();

      expect(filter.eqValues, isEmpty);
      expect(result, hasLength(2));
      expect(result.first['id'], 'e1');
    });

    test('returns empty list on error', () async {
      when(() => mockSupabase.from('exams'))
          .thenAnswer((_) => FakeQueryBuilder(
                onSelect: () => FakeFilterBuilder.error(Exception('db error')),
              ));

      final repo = GateRepository(supabaseService: mockSupabase);
      final result = await repo.listAllExams();

      expect(result, isEmpty);
    });
  });
}
