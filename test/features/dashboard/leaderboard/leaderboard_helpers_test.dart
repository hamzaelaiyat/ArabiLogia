import 'package:arabilogia/features/dashboard/leaderboard/widgets/leaderboard_helpers.dart';

import '../../../helpers/test_helper.dart';

Map<String, dynamic> _row(String id, {int? rank, double score = 0}) => {
  'user_id': id,
  'full_name': 'user $id',
  'total_score': score,
  if (rank != null) 'rank': rank,
};

void main() {
  group('partitionLeaderboard', () {
    test('splits a normal board into podium and remainder', () {
      final rows = [
        _row('a', score: 30),
        _row('b', score: 20),
        _row('c', score: 10),
        _row('d', score: 5),
        _row('e', score: 1),
      ];

      final result = partitionLeaderboard(rows);

      expect(result.podium.map((r) => r['user_id']), ['a', 'b', 'c']);
      expect(result.rest.map((r) => r['user_id']), ['d', 'e']);
    });

    // Regression: every student ties at rank 1 because the RPC ranks on
    // total_score, and no public student has exam results. Filtering on
    // `rank <= 3` put all 21 students in the podium, so the rank-4+ list
    // rendered empty and only three were ever visible.
    test('keeps every row visible when all ranks are tied at 1', () {
      final rows = List.generate(21, (i) => _row('u$i', rank: 1));

      final result = partitionLeaderboard(rows);

      expect(result.podium, hasLength(3));
      expect(result.rest, hasLength(18));
      expect(result.podium.length + result.rest.length, rows.length);
    });

    test('returns every row exactly once for any rank distribution', () {
      final rows = [
        _row('a', rank: 1),
        _row('b', rank: 1),
        _row('c', rank: 1),
        _row('d', rank: 4),
        _row('e', rank: 4),
        _row('f', rank: 6),
      ];

      final result = partitionLeaderboard(rows);
      final ids = [...result.podium, ...result.rest].map((r) => r['user_id']);

      expect(ids.toSet(), hasLength(rows.length));
      expect(ids, containsAllInOrder(['a', 'b', 'c', 'd', 'e', 'f']));
    });

    test('handles boards smaller than the podium', () {
      expect(partitionLeaderboard(const []).podium, isEmpty);
      expect(partitionLeaderboard(const []).rest, isEmpty);

      final one = partitionLeaderboard([_row('a')]);
      expect(one.podium, hasLength(1));
      expect(one.rest, isEmpty);

      final two = partitionLeaderboard([_row('a'), _row('b')]);
      expect(two.podium, hasLength(2));
      expect(two.rest, isEmpty);
    });

    test('does not mutate the source list', () {
      final rows = List.generate(5, (i) => _row('u$i'));

      partitionLeaderboard(rows);

      expect(rows, hasLength(5));
    });
  });

  group('getGradeName', () {
    test('labels the aggregate grade', () {
      expect(getGradeName(0), isNotEmpty);
    });
  });

  group('getAvatar', () {
    test('uses the first character of the name', () {
      expect(getAvatar('محمد'), 'م');
    });

    test('falls back for a blank name', () {
      expect(getAvatar('   '), 'ط');
    });
  });
}
