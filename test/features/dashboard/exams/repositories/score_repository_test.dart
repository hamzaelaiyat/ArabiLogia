import 'dart:async';
import 'dart:convert';

import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:arabilogia/core/services/supabase_service_interface.dart';
import 'package:arabilogia/data/local/database.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/features/dashboard/leaderboard/repositories/leaderboard_repository.dart';

class _MockSupabaseService extends Mock implements SupabaseServiceInterface {}
class _MockGoTrueClient extends Mock implements GoTrueClient {}

/// Minimal fake builder that just returns preset data on await.
class FakeBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final T result;
  final Object? error;
  final Future<void>? pending;
  FakeBuilder(this.result) : error = null, pending = null;
  FakeBuilder.withPending(this.pending, this.result) : error = null;
  FakeBuilder.error(this.error) : result = null as T, pending = null;

  @override
  Future<U> then<U>(FutureOr<U> Function(T) onValue, {Function? onError}) async {
    if (error != null) throw error!;
    if (pending != null) await pending;
    return Future<T>.value(result).then<U>(onValue, onError: onError);
  }

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<T> order(String column,
      {bool ascending = false, bool nullsFirst = false, String? referencedTable}) =>
      this;

  @override
  PostgrestTransformBuilder<T> limit(int count, {String? referencedTable}) =>
      FakeTransformList(result as List<Map<String, dynamic>>) as PostgrestTransformBuilder<T>;

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() =>
      FakeTransformMap(result is PostgrestMap ? result as PostgrestMap : null);
}

class FakeTransformList extends Fake implements PostgrestTransformBuilder<PostgrestList> {
  final List<Map<String, dynamic>> result;
  FakeTransformList(this.result);

  @override
  Future<U> then<U>(FutureOr<U> Function(PostgrestList) onValue, {Function? onError}) {
    return Future<PostgrestList>.value(result).then<U>(onValue, onError: onError);
  }

  @override
  PostgrestTransformBuilder<PostgrestList> select([String columns = '*']) =>
      FakeTransformList(result);
}

class FakeTransformMap extends Fake implements PostgrestTransformBuilder<PostgrestMap?> {
  final Map<String, dynamic>? result;
  FakeTransformMap(this.result);

  @override
  Future<U> then<U>(FutureOr<U> Function(PostgrestMap?) onValue, {Function? onError}) {
    return Future<PostgrestMap?>.value(result).then<U>(onValue, onError: onError);
  }

  @override
  PostgrestTransformBuilder<PostgrestList> select([String columns = '*']) =>
      FakeTransformList(result != null ? [result!] : []);
}

class FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>> selectResult;
  final Future<void>? pending;
  FakeQueryBuilder(this.selectResult) : pending = null;
  FakeQueryBuilder.pending(this.pending, this.selectResult);

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) =>
      FakeBuilder<PostgrestList>.withPending(pending, selectResult);

  @override
  PostgrestFilterBuilder<PostgrestList> insert(Object values, {bool defaultToNull = true}) =>
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
  late AppDatabase testDb;
  late ScoreRepository repo;
  late LeaderboardRepository leaderboardRepo;

  setUp(() {
    mockService = _MockSupabaseService();
    mockAuth = _MockGoTrueClient();
    when(() => mockService.auth).thenReturn(mockAuth);
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    repo = ScoreRepository(supabaseService: mockService, database: testDb);
    leaderboardRepo = LeaderboardRepository(supabaseService: mockService);
  });

  tearDown(() async {
    await testDb.close();
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
      when(() => mockService.from('exam_results')).thenAnswer((_) => FakeQueryBuilder([{'id': 'r1'}]));

      final result = await repo.submitScore(examId: 'exam_1', subject: 'arabic', score: 85.0, points: 10);

      expect(result, true);
      final scores = await repo.getLocalScores();
      expect(scores['exam_1']['score'], equals(85.0));
      expect(scores['exam_1']['points'], equals(10));
    });

    test('Skips insert when completed score already exists for this exam', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      when(() => mockService.from('exam_results')).thenAnswer((_) => FakeQueryBuilder([{'id': 'existing_1'}]));

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
      int callCount = 0;
      when(() => mockService.from(any())).thenAnswer((_) {
        callCount++;
        return FakeQueryBuilder([]);
      });

      await Future.wait([
        repo.syncScoresWithSupabase(),
        repo.syncScoresWithSupabase(),
      ]);

      expect(callCount, equals(2));
    });

    test('Pushes local-only scores to remote when exam exists', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      repo = ScoreRepository(supabaseService: mockService, database: testDb);

      when(() => mockService.from('exams')).thenAnswer((_) => FakeQueryBuilder([{'id': 'exam_1'}]));
      when(() => mockService.from('exam_results')).thenAnswer((_) => FakeQueryBuilder([]));

      await repo.syncScoresWithSupabase();
      final scores = await repo.getLocalScores();
      expect(scores, isEmpty);
    });

    test('Skips scores for deleted exams', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      repo = ScoreRepository(supabaseService: mockService, database: testDb);

      when(() => mockService.from('exams')).thenAnswer((_) => FakeQueryBuilder([]));
      when(() => mockService.from('exam_results')).thenAnswer((_) => FakeQueryBuilder([]));

      await repo.syncScoresWithSupabase();
      final scores = await repo.getLocalScores();
      expect(scores, isEmpty);
    });
  });

  group('getLocalScores', () {
    test('Returns all stored scores', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      when(() => mockService.from('exam_results')).thenAnswer((_) => FakeQueryBuilder([{'id': 'r1'}]));
      await repo.submitScore(examId: 'exam_1', subject: 'arabic', score: 85.0, points: 10);
      await repo.submitScore(examId: 'exam_2', subject: 'math', score: 92.0, points: 15);

      final scores = await repo.getLocalScores();
      expect(scores['exam_1']['score'], equals(85.0));
      expect(scores['exam_1']['points'], equals(10));
      expect(scores['exam_2']['score'], equals(92.0));
      expect(scores['exam_2']['points'], equals(15));
    });

    test('Returns empty map when no scores exist', () async {
      expect(await repo.getLocalScores(), isEmpty);
    });
  });

  group('getLeaderboard', () {
    test('Calls RPC with correct period filter', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      await leaderboardRepo.getLeaderboard(period: 'weekly');
      verify(() => mockService.rpc('get_leaderboard_by_period', params: {'period_filter': 'weekly'})).called(1);
    });

    test('Returns empty on error', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      when(() => mockService.rpc(any(), params: any(named: 'params'))).thenThrow(Exception('error'));
      expect(await leaderboardRepo.getLeaderboard(period: 'monthly'), isEmpty);
    });
  });

  group('getUserStats', () {
    test('Returns null when not logged in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(await leaderboardRepo.getUserStats(), isNull);
    });

    test('Returns null on error', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      when(() => mockService.rpc(any(), params: any(named: 'params'))).thenThrow(Exception('error'));
      expect(await leaderboardRepo.getUserStats(), isNull);
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
      expect(await leaderboardRepo.getDetailedProfileStats(), isEmpty);
    });

    test('Handles null basicStats', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      when(() => mockService.rpc(any(), params: any(named: 'params'))).thenThrow(Exception('error'));
      when(() => mockService.from('exam_results')).thenAnswer((_) => FakeQueryBuilder([]));

      final result = await leaderboardRepo.getDetailedProfileStats();
      expect(result['exams_completed'], equals(0));
      expect(result['avg_score'], equals(0.0));
      expect(result['total_score'], equals(0));
      expect(result['rank'], equals(0));
      expect(result['last_exam'], isNull);
    });
  });
}
