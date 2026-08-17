import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arabilogia/core/services/supabase_service_interface.dart';

export 'package:flutter_test/flutter_test.dart';
export 'package:mocktail/mocktail.dart';
export 'package:supabase_flutter/supabase_flutter.dart';
export 'package:arabilogia/core/services/supabase_service_interface.dart';

class MockSupabaseService extends Mock implements SupabaseServiceInterface {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

User createTestUser({
  String id = 'user_1',
  String email = 'test@example.com',
  Map<String, dynamic>? userMetadata,
}) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: userMetadata ?? const {},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    email: email,
    role: 'authenticated',
  );
}

/// Minimal fake Postgrest filter builder that resolves to a preset list of
/// rows on await, records `eq()` calls, and forwards the query chain to
/// itself. Note: `PostgrestBuilder` implements [Future], so awaiting the
/// returned chain hits the overridden `then`.
class FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  final List<Map<String, dynamic>> rows;
  final Object? error;
  final Map<String, dynamic> eqValues = {};

  FakeFilterBuilder([this.rows = const []]) : error = null;
  FakeFilterBuilder.error(Object this.error) : rows = const [];

  @override
  Future<U> then<U>(
    FutureOr<U> Function(PostgrestList) onValue, {
    Function? onError,
  }) {
    if (error != null) {
      final completer = Completer<PostgrestList>()..completeError(error!);
      return completer.future.then<U>(onValue, onError: onError);
    }
    return Future<PostgrestList>
        .value(rows)
        .then<U>(onValue, onError: onError);
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
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) => this;

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() =>
      FakeSingleBuilder(rows.isEmpty ? null : rows.first);
}

/// Minimal fake transform builder (e.g. from `.maybeSingle()`) that resolves
/// to a preset map on await.
class FakeSingleBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestMap?> {
  final PostgrestMap? result;
  final Object? error;

  FakeSingleBuilder(this.result) : error = null;
  FakeSingleBuilder.error(Object this.error) : result = null;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(PostgrestMap?) onValue, {
    Function? onError,
  }) {
    if (error != null) {
      final completer = Completer<PostgrestMap?>()..completeError(error!);
      return completer.future.then<U>(onValue, onError: onError);
    }
    return Future<PostgrestMap?>.value(result).then<U>(onValue, onError: onError);
  }
}

/// Minimal fake Supabase query builder that returns a preset filter builder
/// from `select()`.
class FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final PostgrestFilterBuilder<PostgrestList> Function()? onSelect;

  FakeQueryBuilder({this.onSelect});

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) =>
      onSelect?.call() ?? FakeFilterBuilder(const []);
}
