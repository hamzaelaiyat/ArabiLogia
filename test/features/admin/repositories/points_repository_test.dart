import 'package:arabilogia/features/admin/repositories/points_repository.dart';

import '../../../helpers/test_helper.dart';

void main() {
  late MockSupabaseService mockSupabase;

  setUp(() {
    mockSupabase = MockSupabaseService();
  });

  group('getStudentsWithBalances', () {
    test('passes the grade straight through as p_grade (no offset)', () async {
      Map<String, dynamic>? capturedParams;
      final filter = FakeFilterBuilder([
        {
          'user_id': 'u1',
          'full_name': 'طالب',
          'grade': 2,
          'total_balance': 5,
        },
      ]);
      when(
        () => mockSupabase.rpc(
          'get_students_with_balances',
          params: any(named: 'params'),
        ),
      ).thenAnswer((invocation) {
        capturedParams =
            invocation.namedArguments[#params] as Map<String, dynamic>?;
        return filter;
      });

      final repo = PointsRepository(supabaseService: mockSupabase);
      final result = await repo.getStudentsWithBalances(grade: 2);

      expect(capturedParams, {'p_grade': 2});
      expect(result, hasLength(1));
      expect(result.first['grade'], 2);
    });

    test('defaults p_grade to 0 (all grades)', () async {
      Map<String, dynamic>? capturedParams;
      when(
        () => mockSupabase.rpc(
          'get_students_with_balances',
          params: any(named: 'params'),
        ),
      ).thenAnswer((invocation) {
        capturedParams =
            invocation.namedArguments[#params] as Map<String, dynamic>?;
        return FakeFilterBuilder(const []);
      });

      final repo = PointsRepository(supabaseService: mockSupabase);
      final result = await repo.getStudentsWithBalances();

      expect(capturedParams, {'p_grade': 0});
      expect(result, isEmpty);
    });
  });

  group('_adjustPoints', () {
    test('increment returns the new balance', () async {
      Map<String, dynamic>? capturedParams;
      final filter = FakeFilterBuilder([{'new_balance': 42}]);
      when(
        () => mockSupabase.rpc(
          'adjust_student_points',
          params: any(named: 'params'),
        ),
      ).thenAnswer((invocation) {
        capturedParams =
            invocation.namedArguments[#params] as Map<String, dynamic>?;
        return filter;
      });

      final repo = PointsRepository(supabaseService: mockSupabase);
      final balance = await repo.incrementPoints('user_1', 10);

      expect(balance, 42);
      expect(capturedParams, {
        'p_user_id': 'user_1',
        'p_amount': 10,
        'p_action': 'increment',
      });
    });
  });

  group('getStudentAdjustments', () {
    test('returns the adjustments history', () async {
      final filter = FakeFilterBuilder([
        {'id': 'a1', 'amount': 5},
      ]);
      when(() => mockSupabase.from('points_adjustments'))
          .thenAnswer((_) => FakeQueryBuilder(onSelect: () => filter));

      final repo = PointsRepository(supabaseService: mockSupabase);
      final result = await repo.getStudentAdjustments('user_1');

      expect(filter.eqValues['user_id'], 'user_1');
      expect(result, hasLength(1));
      expect(result.first['id'], 'a1');
    });

    test('returns empty list on failure', () async {
      final filter = FakeFilterBuilder.error(Exception('boom'));
      when(() => mockSupabase.from('points_adjustments'))
          .thenAnswer((_) => FakeQueryBuilder(onSelect: () => filter));

      final repo = PointsRepository(supabaseService: mockSupabase);
      final result = await repo.getStudentAdjustments('user_1');

      expect(result, isEmpty);
    });
  });
}
