import 'dart:async';

import 'package:arabilogia/core/models/grade_metadata.dart';
import 'package:arabilogia/features/dashboard/leaderboard/repositories/leaderboard_repository.dart';

import '../../../helpers/test_helper.dart';

/// Records `order()` and `eq()` calls so query shape can be asserted.
/// `FakeFilterBuilder` (from test_helper) forwards `order()` to itself and
/// drops the column, so it can't observe tie-breakers or grade filters.
class RecordingFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  final List<Map<String, dynamic>> rows;
  final List<String> orderCalls = [];
  final Map<String, Object?> eqValues = {};

  RecordingFilterBuilder(this.rows);

  @override
  Future<U> then<U>(
    FutureOr<U> Function(PostgrestList) onValue, {
    Function? onError,
  }) {
    return Future<PostgrestList>.value(rows).then<U>(onValue, onError: onError);
  }

  @override
  PostgrestTransformBuilder<PostgrestList> order(
    String column, {
    bool ascending = false,
    bool? nullsFirst,
    String? referencedTable,
  }) {
    orderCalls.add(ascending ? '$column asc' : '$column desc');
    return this;
  }

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    eqValues[column] = value;
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestList> limit(
    int count, {
    String? referencedTable,
  }) => this;
}

void main() {
  late MockSupabaseService mockSupabase;
  late MockGoTrueClient mockAuth;
  late RecordingFilterBuilder builder;

  setUp(() {
    mockSupabase = MockSupabaseService();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);

    builder = RecordingFilterBuilder([
      {'user_id': 'u1', 'total_score': 0.0, 'rank': 1},
      {'user_id': 'u2', 'total_score': 0.0, 'rank': 2},
      {'user_id': 'u3', 'total_score': 0.0, 'rank': 3},
      {'user_id': 'u4', 'total_score': 0.0, 'rank': 4},
    ]);

    when(
      () => mockSupabase.rpc(
        'get_leaderboard_by_period',
        params: any(named: 'params'),
      ),
    ).thenAnswer((_) => builder);
  });

  group('LeaderboardRepository.getLeaderboard ordering', () {
    test('sorts by score then exams completed then user id', () async {
      final repo = LeaderboardRepository(supabaseService: mockSupabase);

      await repo.getLeaderboard();

      // Deterministic tie-breakers matter because the screen renders ranks
      // from list position; an unstable order would shuffle the board between
      // fetches and let the podium disagree with the rows below it.
      expect(builder.orderCalls, [
        'total_score desc',
        'exams_completed desc',
        'user_id asc',
      ]);
    });

    test('returns every row so nothing is dropped below the podium', () async {
      final repo = LeaderboardRepository(supabaseService: mockSupabase);

      final rows = await repo.getLeaderboard();

      expect(rows, hasLength(4));
      expect(rows.map((r) => r['user_id']), ['u1', 'u2', 'u3', 'u4']);
    });

    test('passes the requested period to the rpc', () async {
      final repo = LeaderboardRepository(supabaseService: mockSupabase);

      await repo.getLeaderboard(period: 'week');

      verify(
        () => mockSupabase.rpc(
          'get_leaderboard_by_period',
          params: {'period_filter': 'week'},
        ),
      ).called(1);
    });
  });

  group('LeaderboardRepository.getLeaderboard grade filter', () {
    test('filters by grade when a specific grade is selected', () async {
      final repo = LeaderboardRepository(supabaseService: mockSupabase);

      await repo.getLeaderboard(grade: 3);

      expect(builder.eqValues['grade'], 3);
    });

    test('skips the grade filter for the aggregate grade', () async {
      final repo = LeaderboardRepository(supabaseService: mockSupabase);

      await repo.getLeaderboard(grade: GradeMetadata.allGrades);

      expect(builder.eqValues, isEmpty);
    });

    test('skips the grade filter when no grade is given', () async {
      final repo = LeaderboardRepository(supabaseService: mockSupabase);

      await repo.getLeaderboard();

      expect(builder.eqValues, isEmpty);
    });
  });

  group('LeaderboardRepository.getLeaderboard failure handling', () {
    test('returns an empty list instead of throwing', () async {
      when(
        () => mockSupabase.rpc(
          'get_leaderboard_by_period',
          params: any(named: 'params'),
        ),
      ).thenThrow(Exception('network down'));

      final repo = LeaderboardRepository(supabaseService: mockSupabase);

      expect(await repo.getLeaderboard(), isEmpty);
    });
  });
}
