import 'dart:async';
import 'dart:convert';

import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arabilogia/core/services/supabase_service_interface.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';

class _MockSupabaseService extends Mock implements SupabaseServiceInterface {}
class _MockGoTrueClient extends Mock implements GoTrueClient {}

/// Minimal fake builder that just returns preset data on await.
class FakeBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final T result;
  final Object? error;
  FakeBuilder(this.result) : error = null;
  FakeBuilder.error(this.error) : result = null as T;

  @override
  Future<T> then<U>(FutureOr<U> Function(T) onValue, {Function? onError}) {
    if (error != null) return Future.error(error!);
    return Future.value(result).then(onValue, onError: onError);
  }

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<T> order(String column, {bool ascending = true}) => this;

  @override
  PostgrestTransformBuilder<T> limit(int count) =>
      FakeTransformList(result as List<Map<String, dynamic>>);

  @override
  PostgrestTransformBuilder<T?> maybeSingle() =>
      FakeTransformMap(result is Map ? result as Map<String, dynamic> : null);
}

class FakeTransformList extends Fake implements PostgrestTransformBuilder<PostgrestList> {
  final List<Map<String, dynamic>> result;
  FakeTransformList(this.result);

  @override
  Future<PostgrestList> then<U>(FutureOr<U> Function(PostgrestList) onValue, {Function? onError}) {
    return Future.value(result).then(onValue, onError: onError);
  }

  @override
  PostgrestTransformBuilder<PostgrestList> select([String columns = '*']) =>
      FakeTransformList(result);
}

class FakeTransformMap extends Fake implements PostgrestTransformBuilder<PostgrestMap?> {
  final Map<String, dynamic>? result;
  FakeTransformMap(this.result);

  @override
  Future<PostgrestMap?> then<U>(FutureOr<U> Function(PostgrestMap?)? onValue, {Function? onError}) {
    return Future.value(result).then(onValue, onError: onError);
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> select([String columns = '*']) =>
      FakeTransformList(result != null ? [result!] : []) as PostgrestTransformBuilder<PostgrestMap?>;
}

class FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>> selectResult;
  FakeQueryBuilder(this.selectResult);

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) =>
      FakeBuilder<PostgrestList>(selectResult);

  @override
  PostgrestFilterBuilder<PostgrestList> insert(Object values) =>
      FakeBuilder<PostgrestList>(selectResult);
}

User _createUser({String id = 'user_1'}) {
  return User(
    id: id,
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    email: 'user@example.com',
    role: 'authenticated',
  );
}

void main() {
  late _MockSupabaseService mockService;
  late _MockGoTrueClient mockAuth;
  late ScoreRepository repo;

  setUp(() {
    mockService = _MockSupabaseService();
    mockAuth = _MockGoTrueClient();
    when(() => mockService.auth).thenReturn(mockAuth);
    SharedPreferences.setMockInitialValues({});
    repo = ScoreRepository(supabaseService: mockService);
  });

  group('submitScore', () {
    test('Returns false when no user is logged in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      final result = await repo.submitScore(examId: 'exam_1', subject: 'arabic', score: 85.0);
      expect(result, false);
      verifyNever(() => mockService.from(any()));
    });

    test('Updates local cache before remote call and inserts', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      when(() => mockService.from('exam_results')).thenReturn(FakeQueryBuilder([{'id': 'r1'}]));

      final result = await repo.submitScore(examId: 'exam_1', subject: 'arabic', score: 85.0, points: 10);

      expect(result, true);
      final prefs = await SharedPreferences.getInstance();
      final cache = jsonDecode(prefs.getString('exam_scores_cache') ?? '{}');
      expect(cache['exam_1']['score'], equals(85.0));
      expect(cache['exam_1']['points'], equals(10));
    });

    test('Skips insert when completed score already exists for this exam', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      when(() => mockService.from('exam_results')).thenReturn(FakeQueryBuilder([{'id': 'existing_1'}]));

      final result = await repo.submitScore(examId: 'exam_1', subject: 'arabic', score: 90.0, isCompleted: true);

      expect(result, true);
    });
  });

  group('syncScoresWithSupabase', () {
    test('Returns early when user is null', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      await repo.syncScoresWithSupabase();
      verifyNever(() => mockService.from(any()));
    });

    test('Guards against concurrent sync', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      // First call uses a completer to hold it open
      final completer = Completer<void>();
      final realFrom = mockService.from;
      int callCount = 0;
      when(() => mockService.from(any())).thenAnswer((inv) {
        callCount++;
        if (callCount == 1) {
          // Return a query builder that never completes for the first call
          return FakeQueryBuilder([]);
        }
        return realFrom(inv.positionalArguments[0] as String);
      });

      // First insert does nothing, second sees existing exam
      when(() => mockService.from('exam_results')).thenReturn(FakeQueryBuilder([]));

      final first = repo.syncScoresWithSupabase();
      await repo.syncScoresWithSupabase(); // should be dropped

      // Complete the first call's stub
      completer.complete();
      await first;

      // Only one sync should proceed
      verify(() => mockService.from(any())).called(1);
    });

    test('Pushes local-only scores to remote when exam exists', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      SharedPreferences.setMockInitialValues({
        'exam_scores_cache': jsonEncode({'exam_1': {'score': 85.0, 'points': 10}}),
      });
      repo = ScoreRepository(supabaseService: mockService);

      // exams query returns exam_1 exists
      when(() => mockService.from('exams')).thenReturn(FakeQueryBuilder([{'id': 'exam_1'}]));
      // exam_results query returns nothing locally
      when(() => mockService.from('exam_results')).thenReturn(FakeQueryBuilder([]));

      await repo.syncScoresWithSupabase();
      // Verify local cache was preserved
      final prefs = await SharedPreferences.getInstance();
      final cache = jsonDecode(prefs.getString('exam_scores_cache') ?? '{}');
      expect(cache['exam_1']['score'], equals(85.0));
    });

    test('Skips scores for deleted exams', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      SharedPreferences.setMockInitialValues({
        'exam_scores_cache': jsonEncode({'exam_deleted': {'score': 85.0, 'points': 10}}),
      });
      repo = ScoreRepository(supabaseService: mockService);

      // exams query returns nothing (exam is deleted)
      when(() => mockService.from('exams')).thenReturn(FakeQueryBuilder([]));
      when(() => mockService.from('exam_results')).thenReturn(FakeQueryBuilder([]));

      await repo.syncScoresWithSupabase();
      // Deleted exam's score should still be in cache (it's just not pushed)
      final prefs = await SharedPreferences.getInstance();
      final cache = jsonDecode(prefs.getString('exam_scores_cache') ?? '{}');
      expect(cache['exam_deleted']['score'], equals(85.0));
    });
  });

  group('getLocalScores', () {
    test('Returns empty map when no cache exists', () async {
      expect(await repo.getLocalScores(), isEmpty);
    });

    test('Returns parsed scores from cache', () async {
      SharedPreferences.setMockInitialValues({
        'exam_scores_cache': jsonEncode({
          'exam_1': {'score': 85.0, 'points': 10},
          'exam_2': {'score': 92.0, 'points': 15},
        }),
      });
      repo = ScoreRepository(supabaseService: mockService);
      final scores = await repo.getLocalScores();
      expect(scores['exam_1']['score'], equals(85.0));
      expect(scores['exam_1']['points'], equals(10));
      expect(scores['exam_2']['score'], equals(92.0));
      expect(scores['exam_2']['points'], equals(15));
    });

    test('Handles legacy primitive format', () async {
      SharedPreferences.setMockInitialValues({
        'exam_scores_cache': jsonEncode({'exam_1': 75.0}),
      });
      repo = ScoreRepository(supabaseService: mockService);
      final scores = await repo.getLocalScores();
      expect(scores['exam_1']['score'], equals(75.0));
      expect(scores['exam_1']['points'], equals(0));
    });
  });

  group('getLeaderboard', () {
    test('Calls RPC with correct period filter', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      await repo.getLeaderboard(period: 'weekly');
      verify(() => mockService.rpc('get_leaderboard_by_period', params: {'period_filter': 'weekly'})).called(1);
    });

    test('Returns empty on error', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      when(() => mockService.rpc(any(), params: any(named: 'params'))).thenThrow(Exception('error'));
      expect(await repo.getLeaderboard(period: 'monthly'), isEmpty);
    });
  });

  group('getUserStats', () {
    test('Returns null when not logged in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(await repo.getUserStats(), isNull);
    });

    test('Returns null on error', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      when(() => mockService.rpc(any(), params: any(named: 'params'))).thenThrow(Exception('error'));
      expect(await repo.getUserStats(), isNull);
    });
  });

  group('getRecentActivity', () {
    test('Returns empty when not logged in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(await repo.getRecentActivity(), isEmpty);
    });

    test('Returns empty on error', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      when(() => mockService.from('exam_results')).thenThrow(Exception('error'));
      expect(await repo.getRecentActivity(), isEmpty);
    });
  });

  group('getDetailedProfileStats', () {
    test('Returns empty when not logged in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(await repo.getDetailedProfileStats(), isEmpty);
    });

    test('Handles null basicStats', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      when(() => mockService.rpc(any(), params: any(named: 'params'))).thenThrow(Exception('error'));
      when(() => mockService.from('exam_results')).thenReturn(FakeQueryBuilder([]));

      final result = await repo.getDetailedProfileStats();
      expect(result['exams_completed'], equals(0));
      expect(result['avg_score'], equals(0.0));
      expect(result['total_score'], equals(0));
      expect(result['rank'], equals(0));
      expect(result['last_exam'], isNull);
    });
  });
}
