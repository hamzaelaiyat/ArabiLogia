import 'package:arabilogia/core/services/profile_service.dart';

import '../../helpers/test_helper.dart';

class _FakeProfileDatabase implements IProfileDatabase {
  Map<String, Map<String, dynamic>> profiles = {};
  Map<String, dynamic>? lastAuthUpdateData;
  User? fakeCurrentUser;
  bool throwOnUpdate = false;

  @override
  Future<Map<String, dynamic>?> fetchSingle(
    String table,
    String columns,
    String id,
  ) async {
    if (table == 'profiles' && profiles.containsKey(id)) {
      final profile = profiles[id]!;
      final result = <String, dynamic>{};
      for (final col in columns.split(', ')) {
        if (profile.containsKey(col)) {
          result[col] = profile[col];
        }
      }
      return result;
    }
    return null;
  }

  @override
  Future<void> update(String table, Map<String, dynamic> values, String id) async {
    if (throwOnUpdate) {
      throw const PostgrestException(message: 'duplicate key', code: '23505');
    }
    if (table == 'profiles') {
      profiles[id] = {...(profiles[id] ?? {}), ...values};
    }
  }

  @override
  Future<UserResponse> updateAuthUser(UserAttributes attributes) async {
    lastAuthUpdateData = attributes.data as Map<String, dynamic>?;
    return UserResponse.fromJson({
      'id': fakeCurrentUser?.id ?? 'user_1',
      'app_metadata': <String, dynamic>{},
      'user_metadata': lastAuthUpdateData ?? <String, dynamic>{},
      'aud': 'authenticated',
      'created_at': DateTime.now().toIso8601String(),
      'role': 'authenticated',
    });
  }

  @override
  User? get currentUser => fakeCurrentUser;

  @override
  Future<UserResponse> getUser() async => UserResponse.fromJson({
        'id': fakeCurrentUser?.id ?? 'user_1',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'aud': 'authenticated',
        'created_at': DateTime.now().toIso8601String(),
        'role': 'authenticated',
      });
}

void main() {
  late MockSupabaseService mockSupabase;
  late _FakeProfileDatabase fakeDb;
  late DateTime fixedNow;

  setUp(() {
    mockSupabase = MockSupabaseService();
    fakeDb = _FakeProfileDatabase();
    fixedNow = DateTime(2026, 8, 3, 12, 0, 0);
  });

  ProfileService service() => ProfileService(
        mockSupabase,
        db: fakeDb,
        now: () => fixedNow,
      );

  group('updateProfile grade handling', () {
    test('blocks a grade change within the 3-day lock', () async {
      fakeDb.profiles['user_1'] = {
        'grade': 2,
        'grade_updated_at': fixedNow.subtract(const Duration(days: 1)).toIso8601String(),
      };

      final result = await service().updateProfile(
        userId: 'user_1',
        grade: 3,
      );

      expect(result.success, isFalse);
      expect(result.error, contains('بعد'));
      expect(fakeDb.lastAuthUpdateData, isNull);
      expect(fakeDb.profiles['user_1']!['grade'], 2);
    });

    test('allows a grade change after the lock window and stores the id directly',
        () async {
      fakeDb.profiles['user_1'] = {
        'grade': 2,
        'grade_updated_at': fixedNow.subtract(const Duration(days: 4)).toIso8601String(),
      };

      final result = await service().updateProfile(
        userId: 'user_1',
        grade: 3,
      );

      expect(result.success, isTrue);
      expect(fakeDb.profiles['user_1']!['grade'], 3);
      expect(fakeDb.lastAuthUpdateData?['grade'], 3);
      expect(
        fakeDb.profiles['user_1']!['grade_updated_at'],
        fixedNow.toIso8601String(),
      );
    });

    test('leaves grade untouched when it did not change', () async {
      fakeDb.profiles['user_1'] = {
        'grade': 2,
        'grade_updated_at': fixedNow.subtract(const Duration(days: 1)).toIso8601String(),
      };

      final result = await service().updateProfile(
        userId: 'user_1',
        grade: 2,
      );

      expect(result.success, isTrue);
      expect(fakeDb.profiles['user_1']!['grade'], 2);
      expect(
        fakeDb.profiles['user_1']!['grade_updated_at'],
        isNot(fixedNow.toIso8601String()),
      );
    });
  });

  group('updateProfile other fields', () {
    test('updates full name through auth metadata', () async {
      fakeDb.profiles['user_1'] = {'grade': 2, 'grade_updated_at': ''};

      final result = await service().updateProfile(
        userId: 'user_1',
        fullName: 'اسم جديد',
      );

      expect(result.success, isTrue);
      expect(fakeDb.profiles['user_1']!['full_name'], 'اسم جديد');
      expect(fakeDb.lastAuthUpdateData?['full_name'], 'اسم جديد');
    });

    test('maps database errors to an Arabic message', () async {
      fakeDb.profiles['user_1'] = {'grade': 2, 'grade_updated_at': ''};
      fakeDb.throwOnUpdate = true;

      final result = await service().updateProfile(
        userId: 'user_1',
        fullName: 'اسم',
      );

      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });
  });
}
