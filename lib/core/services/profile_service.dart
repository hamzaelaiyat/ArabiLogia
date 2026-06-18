import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arabilogia/core/services/supabase_service_interface.dart';
import 'package:arabilogia/core/utils/auth_error_mapper.dart';

class ProfileUpdateResult {
  final bool success;
  final User? user;
  final String? error;
  const ProfileUpdateResult({
    required this.success,
    this.user,
    this.error,
  });
}

class ViolationState {
  final int imageViolationCount;
  final DateTime? imageBlockedUntil;
  final bool hasBadTag;
  const ViolationState({
    this.imageViolationCount = 0,
    this.imageBlockedUntil,
    this.hasBadTag = false,
  });
}

abstract class IProfileDatabase {
  Future<Map<String, dynamic>?> fetchSingle(
      String table, String columns, String id);
  Future<void> update(String table, Map<String, dynamic> values, String id);
  Future<UserResponse> updateAuthUser(UserAttributes attributes);
  User? get currentUser;
  Future<UserResponse> getUser();
}

class SupabaseProfileDatabase implements IProfileDatabase {
  final SupabaseServiceInterface _supabase;

  SupabaseProfileDatabase(this._supabase);

  @override
  Future<Map<String, dynamic>?> fetchSingle(
      String table, String columns, String id) async {
    try {
      return await _supabase.client
          .from(table)
          .select(columns)
          .eq('id', id)
          .single();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> update(
      String table, Map<String, dynamic> values, String id) async {
    await _supabase.client.from(table).update(values).eq('id', id);
  }

  @override
  Future<UserResponse> updateAuthUser(UserAttributes attributes) async {
    return _supabase.auth.updateUser(attributes);
  }

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  Future<UserResponse> getUser() async {
    return _supabase.auth.getUser();
  }
}

class ProfileService {
  final SupabaseServiceInterface _supabase;
  final IProfileDatabase _db;
  final DateTime Function() _now;

  GoTrueClient get _auth => _supabase.auth;

  ProfileService(
    this._supabase, {
    IProfileDatabase? db,
    DateTime Function()? now,
  })  : _db = db ?? SupabaseProfileDatabase(_supabase),
        _now = now ?? (() => DateTime.now());

  Future<String?> loadRole() async {
    return await loadRoleFromServer() ??
        _auth.currentUser?.userMetadata?['role'] as String?;
  }

  Future<String?> loadRoleFromServer() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final response = await _db.fetchSingle('profiles', 'role', user.id);
    return response?['role'] as String?;
  }

  Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final response = await _db.fetchSingle('profiles', 'role', user.id);
      return response?['role'] as String?;
    } catch (e) {
      return user.userMetadata?['role'] as String?;
    }
  }

  Future<ViolationState> loadViolationState() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return const ViolationState();
      final profile = await _db.fetchSingle(
        'profiles',
        'image_violation_count, image_blocked_until, has_bad_tag, last_violation_at',
        user.id,
      );
      if (profile == null) return const ViolationState();
      return ViolationState(
        imageViolationCount:
            profile['image_violation_count'] as int? ?? 0,
        imageBlockedUntil: profile['image_blocked_until'] != null
            ? DateTime.parse(profile['image_blocked_until'] as String)
            : null,
        hasBadTag: profile['has_bad_tag'] as bool? ?? false,
      );
    } catch (e) {
      return const ViolationState();
    }
  }

  Future<ProfileUpdateResult> updateProfile({
    required String userId,
    String? fullName,
    String? username,
    String? avatarUrl,
    int? grade,
    bool? isPublic,
    bool? hideAvatar,
    bool? hideName,
    String? randomName,
    Map<String, bool>? notifications,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      final Map<String, dynamic> profileUpdate = {};

      if (fullName != null) {
        data['full_name'] = fullName;
        profileUpdate['full_name'] = fullName;
      }
      if (username != null) {
        data['username'] = username;
        profileUpdate['username'] = username;
      }
      if (avatarUrl != null) {
        data['avatar_url'] = avatarUrl;
        data['avatar_updated_at'] = _now().toIso8601String();
        profileUpdate['avatar_url'] = avatarUrl;
      }
      if (grade != null) {
        final profile =
            await _db.fetchSingle('profiles', 'grade_updated_at, grade', userId);
        if (profile == null) {
          return const ProfileUpdateResult(
            success: false,
            error: 'حدث خطأ في تحديث البيانات',
          );
        }

        final lastUpdate = DateTime.parse(profile['grade_updated_at']);
        final currentGrade = profile['grade'] as int;

        if (currentGrade != grade) {
          final diff = _now().difference(lastUpdate);
          if (diff.inDays < 3) {
            final remainingInHours = 72 - diff.inHours;
            final remainingInDays = (remainingInHours / 24).ceil();
            return ProfileUpdateResult(
              success: false,
              error: 'يمكنك تغيير الصف الدراسي بعد $remainingInDays يوم',
            );
          }
          data['grade'] = grade;
          profileUpdate['grade'] = grade;
          profileUpdate['grade_updated_at'] = _now().toIso8601String();
        }
      }
      if (isPublic != null) {
        data['is_public'] = isPublic;
        profileUpdate['is_public'] = isPublic;
      }
      if (hideAvatar != null) {
        profileUpdate['hide_avatar'] = hideAvatar;
      }
      if (hideName != null) {
        profileUpdate['hide_name'] = hideName;
      }
      if (randomName != null) {
        profileUpdate['random_name'] = randomName;
      } else if (hideName == false && hideName != null) {
        profileUpdate['random_name'] = null;
      }
      if (notifications != null) {
        data['notifications'] = notifications;
      }

      if (profileUpdate.isNotEmpty) {
        await _db.update('profiles', profileUpdate, userId);
      }

      data.removeWhere((_, v) => v == null);
      final response = await _db.updateAuthUser(UserAttributes(data: data));

      return ProfileUpdateResult(success: true, user: response.user);
    } on PostgrestException catch (e) {
      final errorMsg = getArabicDbError('${e.code} ${e.message}');
      return ProfileUpdateResult(success: false, error: errorMsg);
    } on AuthException catch (e) {
      return ProfileUpdateResult(
        success: false,
        error: getArabicAuthError(e.message),
      );
    } catch (e) {
      return const ProfileUpdateResult(
        success: false,
        error: 'حدث خطأ في تحديث البيانات',
      );
    }
  }

  Future<User?> refreshUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final response = await _db.getUser();
        return response.user ?? user;
      }
      return null;
    } catch (e) {
      return _auth.currentUser;
    }
  }
}
