import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arabilogia/core/services/profile_service.dart';
import 'package:arabilogia/core/services/supabase_service_interface.dart';

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _FakeProfileDatabase implements IProfileDatabase {
  Map<String, Map<String, dynamic>> profiles = {};
  Map<String, dynamic>? lastAuthUpdateAttributes;
  User? fakeCurrentUser;
  UserResponse? getUserResponse;
  bool throwOnUpdate = false;
  bool throwOnGetUser = false;

  @override
  Future<Map<String, dynamic>?> fetchSingle(
      String table, String columns, String id) async {
    if (table == 'profiles' && profiles.containsKey(id)) {
      final profile = Map<String, dynamic>.from(profiles[id]!);
      final result = <String, dynamic>{};
      for (final col in columns.split(', ')) {
        if (profile.containsKey(col)) {
          result[col] = profile[col];
        }
      }
      return result;
    }
    return <String, dynamic>{};
  }

  @override
  Future<void> update(
      String table, Map<String, dynamic> values, String id) async {
    if (throwOnUpdate) {
      throw const PostgrestException(message: 'duplicate key', code: '23505');
    }
    if (table == 'profiles') {
      profiles[id] = {...(profiles[id] ?? {}), ...values};
    }
  }

  @override
  Future<UserResponse> updateAuthUser(UserAttributes attributes) async {
    final data = attributes.data as Map<String, dynamic>?;
    lastAuthUpdateAttributes = data;
    return UserResponse.fromJson({
      'id': fakeCurrentUser?.id ?? 'user_1',
      'app_metadata': <String, dynamic>{},
      'user_metadata': data ?? <String, dynamic>{},
      'aud': 'authenticated',
      'created_at': DateTime.now().toIso8601String(),
      'role': 'authenticated',
    });
  }

  @override
  User? get currentUser => fakeCurrentUser;

  @override
  Future<UserResponse> getUser() async {
    if (throwOnGetUser) throw Exception('Server error');
    return getUserResponse ??
        UserResponse.fromJson({
          'id': fakeCurrentUser?.id ?? 'user_1',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': DateTime.now().toIso8601String(),
          'role': 'authenticated',
        });
  }
}

User _createUser(
    {String id = 'user_1', Map<String, dynamic>? metadata}) {
  return User(
    id: id,
    appMetadata: {},
    userMetadata: metadata ?? {'role': 'student'},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    email: 'test@example.com',
    role: 'authenticated',
  );
}

void main() {
  late _MockGoTrueClient mockAuth;
  late _FakeProfileDatabase fakeDb;
  late ProfileService profileService;

  setUp(() {
    mockAuth = _MockGoTrueClient();
    fakeDb = _FakeProfileDatabase();
    final fakeSupabase = _FakeSupabaseService(mockAuth);
    profileService = ProfileService(
      fakeSupabase,
      db: fakeDb,
    );
  });

  group('loadRole', () {
    test('returns role from server when available', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      fakeDb.profiles['user_1'] = {'role': 'teacher'};

      final role = await profileService.loadRole();

      expect(role, equals('teacher'));
    });

    test('falls back to user metadata when server has no role', () async {
      when(() => mockAuth.currentUser).thenReturn(
        _createUser(metadata: {'role': 'student'}),
      );
      fakeDb.profiles['user_1'] = {};

      final role = await profileService.loadRole();

      expect(role, equals('student'));
    });

    test('returns null when no user is logged in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final role = await profileService.loadRole();

      expect(role, isNull);
    });
  });

  group('loadViolationState', () {
    test('returns clean state when no violations', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      fakeDb.profiles['user_1'] = {
        'image_violation_count': 0,
        'image_blocked_until': null,
        'has_bad_tag': false,
      };

      final state = await profileService.loadViolationState();

      expect(state.imageViolationCount, equals(0));
      expect(state.imageBlockedUntil, isNull);
      expect(state.hasBadTag, isFalse);
    });

    test('returns violation state when user is blocked', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      final blockedUntil =
          DateTime.now().add(const Duration(days: 7)).toIso8601String();
      fakeDb.profiles['user_1'] = {
        'image_violation_count': 3,
        'image_blocked_until': blockedUntil,
        'has_bad_tag': true,
      };

      final state = await profileService.loadViolationState();

      expect(state.imageViolationCount, equals(3));
      expect(state.imageBlockedUntil, isNotNull);
      expect(state.hasBadTag, isTrue);
    });

    test('returns clean state when user is null', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final state = await profileService.loadViolationState();

      expect(state.imageViolationCount, equals(0));
      expect(state.imageBlockedUntil, isNull);
      expect(state.hasBadTag, isFalse);
    });
  });

  group('getUserRole', () {
    test('returns role from server', () async {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
      fakeDb.profiles['user_1'] = {'role': 'admin'};

      final role = await profileService.getUserRole();

      expect(role, equals('admin'));
    });

    test('returns null when role is not set in profile', () async {
      when(() => mockAuth.currentUser).thenReturn(
        _createUser(metadata: {'role': 'student'}),
      );
      fakeDb.profiles['user_1'] = {};

      final role = await profileService.getUserRole();

      expect(role, isNull);
    });

    test('returns null when no user', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final role = await profileService.getUserRole();

      expect(role, isNull);
    });
  });

  group('updateProfile', () {
    setUp(() {
      when(() => mockAuth.currentUser).thenReturn(_createUser());
    });

    test('updates fullName and username successfully', () async {
      fakeDb.profiles['user_1'] = {'role': 'student'};

      final result = await profileService.updateProfile(
        userId: 'user_1',
        fullName: 'Updated Name',
        username: 'updated',
      );

      expect(result.success, isTrue);
      expect(result.error, isNull);
    });

    group('grade update rate limiting', () {
      test('rejects grade change when less than 3 days have passed',
          () async {
        final recentUpdate =
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
        fakeDb.profiles['user_1'] = {
          'grade_updated_at': recentUpdate,
          'grade': 1,
        };

        final result = await profileService.updateProfile(
          userId: 'user_1',
          grade: 2,
        );

        expect(result.success, isFalse);
        expect(result.error, contains('يوم'));
      });

      test('allows grade change after 3 days', () async {
        final oldUpdate =
            DateTime.now()
                .subtract(const Duration(days: 4))
                .toIso8601String();
        fakeDb.profiles['user_1'] = {
          'grade_updated_at': oldUpdate,
          'grade': 1,
        };

        final result = await profileService.updateProfile(
          userId: 'user_1',
          grade: 2,
        );

        expect(result.success, isTrue);
        expect(result.error, isNull);
      });

      test('skips rate limiting when grade has not changed', () async {
        final recentUpdate =
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
        fakeDb.profiles['user_1'] = {
          'grade_updated_at': recentUpdate,
          'grade': 2,
        };

        final result = await profileService.updateProfile(
          userId: 'user_1',
          grade: 2,
        );

        expect(result.success, isTrue);
      });

      test('uses injected clock for rate limiting decisions', () async {
        final fixedNow = DateTime(2025, 6, 15, 12, 0, 0);
        final fourDaysAgo =
            fixedNow.subtract(const Duration(days: 4)).toIso8601String();
        fakeDb.profiles['user_1'] = {
          'grade_updated_at': fourDaysAgo,
          'grade': 1,
        };
        final fakeSupabase = _FakeSupabaseService(mockAuth);
        profileService = ProfileService(
          fakeSupabase,
          db: fakeDb,
          now: () => fixedNow,
        );

        final result = await profileService.updateProfile(
          userId: 'user_1',
          grade: 2,
        );

        expect(result.success, isTrue);
      });
    });

    test('handles PostgrestException correctly', () async {
      fakeDb.profiles['user_1'] = {'role': 'student'};
      fakeDb.throwOnUpdate = true;

      final result = await profileService.updateProfile(
        userId: 'user_1',
        username: 'taken',
      );

      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('updates isPublic and hideAvatar without grade', () async {
      fakeDb.profiles['user_1'] = {'role': 'student'};

      final result = await profileService.updateProfile(
        userId: 'user_1',
        isPublic: false,
        hideAvatar: true,
      );

      expect(result.success, isTrue);
    });
  });

  group('refreshUser', () {
    test('returns updated user from server', () async {
      final user = _createUser();
      when(() => mockAuth.currentUser).thenReturn(user);
      fakeDb.getUserResponse = UserResponse.fromJson({
        'id': 'user_1',
        'app_metadata': <String, dynamic>{},
        'user_metadata': {'role': 'teacher'},
        'aud': 'authenticated',
        'created_at': DateTime.now().toIso8601String(),
        'role': 'authenticated',
      });

      final result = await profileService.refreshUser();

      expect(result, isNotNull);
      expect(result!.id, equals('user_1'));
    });

    test('returns null when no user is logged in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await profileService.refreshUser();

      expect(result, isNull);
    });

    test('returns current user on error', () async {
      final user = _createUser();
      when(() => mockAuth.currentUser).thenReturn(user);
      fakeDb.throwOnGetUser = true;

      final result = await profileService.refreshUser();

      expect(result, isNotNull);
      expect(result!.id, equals('user_1'));
    });
  });
}

class _FakeSupabaseService implements SupabaseServiceInterface {
  final _MockGoTrueClient _mockAuth;
  _FakeSupabaseService(this._mockAuth);

  @override
  GoTrueClient get auth => _mockAuth;

  @override
  SupabaseClient get client =>
      throw UnimplementedError('client not used in tests');

  @override
  SupabaseQueryBuilder from(String table) =>
      throw UnimplementedError('from not used in tests');

  @override
  SupabaseStorageClient get storage =>
      throw UnimplementedError('storage not used in tests');

  @override
  PostgrestFilterBuilder<dynamic> rpc(String fn,
          {Map<String, dynamic>? params}) =>
      throw UnimplementedError('rpc not used in tests');

  @override
  User? get currentUser => _mockAuth.currentUser;

  @override
  Session? get currentSession => _mockAuth.currentSession;

  @override
  bool get isAuthenticated => currentSession != null;

  @override
  String? get userId => currentUser?.id;

  @override
  String? get userEmail => currentUser?.email;

  @override
  Stream<AuthState> get authStateChanges =>
      throw UnimplementedError('authStateChanges not used in tests');
}
