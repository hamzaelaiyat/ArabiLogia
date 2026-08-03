import 'dart:async';

import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';

import '../../../../helpers/test_helper.dart';

/// Fake RPC builder that resolves to either a Map or List when awaited.
/// `FakeFilterBuilder` (from test_helper) only resolves to a PostgrestList,
/// which doesn't match `rpc()` returning a single object.
class FakeRpcFilterBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  final Object value;
  FakeRpcFilterBuilder(this.value);

  @override
  Future<U> then<U>(
    FutureOr<U> Function(dynamic) onValue, {
    Function? onError,
  }) {
    return Future<dynamic>.value(value).then<U>(onValue, onError: onError);
  }
}

PostgrestFilterBuilder<dynamic> _jsonRpc(Object? result) {
  return FakeRpcFilterBuilder(result ?? const {});
}

void main() {
  late MockSupabaseService mockSupabase;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockSupabase = MockSupabaseService();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
  });

  group('ScoreRepository.startExam', () {
    test('returns session metadata on success', () async {
      when(() => mockAuth.currentUser).thenReturn(createTestUser());
      when(() => mockSupabase.rpc(
            'start_exam',
            params: {'p_exam_id': 'e1'},
          )).thenAnswer((_) => _jsonRpc({
                'session_id': 'sess-1',
                'started_at': '2026-08-03T12:00:00Z',
                'duration_seconds': 1800,
              }));

      final repo = ScoreRepository(supabaseService: mockSupabase);
      final info = await repo.startExam('e1');

      expect(info, isNotNull);
      expect(info!.sessionId, 'sess-1');
      expect(info.durationSeconds, 1800);
      expect(info.startedAt.toUtc(), DateTime.utc(2026, 8, 3, 12, 0, 0));
    });

    test('returns null when not authenticated', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      final repo = ScoreRepository(supabaseService: mockSupabase);
      expect(await repo.startExam('e1'), isNull);
    });

    test('returns null when the RPC throws', () async {
      when(() => mockAuth.currentUser).thenReturn(createTestUser());
      when(() => mockSupabase.rpc(
            'start_exam',
            params: any(named: 'params'),
          )).thenThrow(Exception('rpc down'));
      final repo = ScoreRepository(supabaseService: mockSupabase);
      expect(await repo.startExam('e1'), isNull);
    });
  });

  group('ScoreRepository.submitExamAnswer', () {
    test('encodes the answers map and parses the grading payload', () async {
      when(() => mockAuth.currentUser).thenReturn(createTestUser());
      when(() => mockSupabase.rpc(
            'submit_exam_answer',
            params: {
              'p_exam_id': 'e1',
              'p_answers': '{"0":"o1","1":"o0"}',
              'p_session_id': 'sess-1',
            },
          )).thenAnswer((_) => _jsonRpc({
                'exam_id': 'e1',
                'score': 87.5,
                'correct_count': 4,
                'total_count': 5,
                'wrong_mask': 8,
                'accuracy': 80.0,
                'speed_bonus': 7.5,
                'points': 4,
                'status': 'completed',
              }));

      final repo = ScoreRepository(supabaseService: mockSupabase);
      final result = await repo.submitExamAnswer(
        examId: 'e1',
        answers: const {0: 'o1', 1: 'o0'},
        sessionId: 'sess-1',
      );

      expect(result, isNotNull);
      expect(result!.score, 87.5);
      expect(result.correctCount, 4);
      expect(result.totalCount, 5);
      expect(result.wrongMask, 8);
      expect(result.points, 4);
      expect(result.status, 'completed');
    });

    test('omits p_session_id when no session id is provided', () async {
      when(() => mockAuth.currentUser).thenReturn(createTestUser());
      when(() => mockSupabase.rpc(
            'submit_exam_answer',
            params: {
              'p_exam_id': 'e1',
              'p_answers': '{}',
            },
          )).thenAnswer((_) => _jsonRpc({
                'exam_id': 'e1',
                'score': 0.0,
                'correct_count': 0,
                'total_count': 0,
                'wrong_mask': 0,
                'accuracy': 0.0,
                'speed_bonus': 0.0,
                'points': 0,
                'status': 'completed',
              }));

      final repo = ScoreRepository(supabaseService: mockSupabase);
      final result = await repo.submitExamAnswer(
        examId: 'e1',
        answers: const {},
      );
      expect(result, isNotNull);
      verify(() => mockSupabase.rpc(
            'submit_exam_answer',
            params: {
              'p_exam_id': 'e1',
              'p_answers': '{}',
            },
          )).called(1);
    });
  });

  group('ScoreRepository.getExamReview', () {
    test('parses data + answers from the review RPC', () async {
      when(() => mockAuth.currentUser).thenReturn(createTestUser());
      when(() => mockSupabase.rpc(
            'get_exam_review',
            params: {'p_exam_id': 'e1'},
          )).thenAnswer((_) => _jsonRpc({
                'data': {
                  'p': 1,
                  'q': [
                    {'t': 'Q?', 'o': ['A', 'B']},
                  ],
                },
                'answers': {'0': 1},
              }));

      final repo = ScoreRepository(supabaseService: mockSupabase);
      final review = await repo.getExamReview('e1');

      expect(review, isNotNull);
      expect(review!.answers, {'0': 1});
      expect(review.data['p'], 1);
    });
  });
}
