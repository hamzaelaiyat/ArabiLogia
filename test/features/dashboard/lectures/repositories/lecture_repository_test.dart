import 'package:arabilogia/features/dashboard/lectures/repositories/lecture_repository.dart';

import '../../../../helpers/test_helper.dart';

void main() {
  late MockSupabaseService mockSupabase;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockSupabase = MockSupabaseService();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
  });

  group('getLecturesByCategory', () {
    test('filters by course_id and is_published; grade is enforced by RLS',
        () async {
      when(() => mockAuth.currentUser)
          .thenReturn(createTestUser(userMetadata: {'grade': 2}));

      final filter = FakeFilterBuilder([
        {
          'id': 'l1',
          'course_id': 'c1',
          'grade': 2,
          'is_published': true,
          'sort_order': 1,
          'title': 'درس',
          'blocks': const [],
          'created_at': DateTime.now().toIso8601String(),
        },
      ]);
      when(() => mockSupabase.from('lectures'))
          .thenAnswer((_) => FakeQueryBuilder(onSelect: () => filter));

      final repo = LectureRepository(supabaseService: mockSupabase);
      final result = await repo.getLecturesByCategory('c1');

      expect(filter.eqValues['course_id'], 'c1');
      expect(filter.eqValues['is_published'], true);
      expect(filter.eqValues.containsKey('grade'), isFalse,
          reason: 'grade is enforced server-side via RLS');
      expect(result, hasLength(1));
      expect(result.first['id'], 'l1');
    });

    test('returns empty list on error', () async {
      when(() => mockAuth.currentUser)
          .thenReturn(createTestUser(userMetadata: {'grade': 3}));
      when(() => mockSupabase.from('lectures'))
          .thenAnswer((_) => FakeQueryBuilder(
                onSelect: () => FakeFilterBuilder.error(Exception('boom')),
              ));

      final repo = LectureRepository(supabaseService: mockSupabase);
      final result = await repo.getLecturesByCategory('c1');

      expect(result, isEmpty);
    });
  });

  group('getLecturesManaged', () {
    test('returns the managed lectures', () async {
      final filter = FakeFilterBuilder([
        {'id': 'l1', 'title': 'درس'},
      ]);
      when(() => mockSupabase.from('lectures'))
          .thenAnswer((_) => FakeQueryBuilder(onSelect: () => filter));

      final repo = LectureRepository(supabaseService: mockSupabase);
      final result = await repo.getLecturesManaged();

      expect(result, hasLength(1));
    });
  });
}
