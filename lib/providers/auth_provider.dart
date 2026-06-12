import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:arabilogia/core/config/supabase_config.dart';
import 'package:arabilogia/core/utils/auth_error_mapper.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final Session? session;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.session,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    Session? session,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      session: session ?? this.session,
      error: error,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  GoTrueClient? _auth;

  AuthState _state = const AuthState();
  AuthState get state => _state;

  String? _role;
  String? get role => _role;

  int _imageViolationCount = 0;
  DateTime? _imageBlockedUntil;
  bool _hasBadTag = false;

  bool get canUploadAvatar => !_hasBadTag && (_imageBlockedUntil == null || _imageBlockedUntil!.isBefore(DateTime.now()));
  int get imageViolationCount => _imageViolationCount;
  DateTime? get imageBlockedUntil => _imageBlockedUntil;
  bool get hasBadTag => _hasBadTag;

  GoTrueClient get _authClient {
    _auth ??= Supabase.instance.client.auth;
    return _auth!;
  }

  AuthProvider() {
    // Don't initialize here - wait for Supabase to be ready
  }

  Future<void> initializeAfterSupabase() async {
    if (!SupabaseConfig.isConfigured) return;

    try {
      _auth = Supabase.instance.client.auth;
      _state = _state.copyWith(
        isAuthenticated: _auth!.currentSession != null,
        user: _auth!.currentUser,
        session: _auth!.currentSession,
      );

      if (_auth!.currentSession != null) {
        await Future.wait([
          loadViolationState(),
          _loadRole(),
        ]);
      }

      _auth!.onAuthStateChange.listen((event) {
        _state = _state.copyWith(
          isAuthenticated: event.session != null,
          user: event.session?.user,
          session: event.session,
        );
        if (event.session != null) {
          loadViolationState();
          _loadRole();
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('AuthProvider initialization failed: $e');
    }
  }

  Future<void> _loadRole() async {
    try {
      final user = _auth?.currentUser;
      if (user == null) return;
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      _role = response['role'] as String?;
    } catch (e) {
      _role = _state.user?.userMetadata?['role'] as String?;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      final response = await _authClient.signInWithPassword(
        email: email,
        password: password,
      );

      _state = _state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: response.user,
        session: response.session,
      );

      // Sync scores immediately after successful authentication (fire-and-forget)
      unawaited(ScoreRepository().syncScoresWithSupabase());

      // Sync role from auth metadata to profiles table if needed (fire-and-forget)
      unawaited(_syncRoleToProfiles());

      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('SignIn AuthError: ${e.message}');
      _state = _state.copyWith(
        isLoading: false,
        error: getArabicAuthError(e.message),
      );
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('SignIn UnexpectedError: $e');
      _state = _state.copyWith(
        isLoading: false,
        error: 'حدث خطأ، يرجى المحاولة مرة أخرى',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(
    String email,
    String password,
    String fullName,
    String username,
    int grade,
  ) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      final signInResponse = await _authClient.signInWithPassword(
        email: email,
        password: password,
      );

      if (signInResponse.session != null) {
        _state = _state.copyWith(
          isLoading: false,
          error: 'لديك حساب بالفعل، يرجى تسجيل الدخول',
        );
        notifyListeners();
        return false;
      }

      _state = _state.copyWith(isLoading: false, user: signInResponse.user);
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        try {
          final response = await _authClient.signUp(
            email: email,
            password: password,
            data: {'full_name': fullName, 'username': username, 'grade': grade},
          );

          _state = _state.copyWith(isLoading: false, user: response.user);

          unawaited(ScoreRepository().syncScoresWithSupabase());

          notifyListeners();
          return true;
        } catch (signUpError) {
          debugPrint('SignUp AuthError: ${signUpError}');
          _state = _state.copyWith(
            isLoading: false,
            error: getArabicAuthError(signUpError.toString()),
          );
          notifyListeners();
          return false;
        }
      }

      debugPrint('SignIn check AuthError: ${e.message}');
      _state = _state.copyWith(
        isLoading: false,
        error: getArabicAuthError(e.message),
      );
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('SignUp UnexpectedError: $e');
      _state = _state.copyWith(
        isLoading: false,
        error: 'حدث خطأ، يرجى المحاولة مرة أخرى',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String token) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      // Prefer signup OTP, then fall back to email OTP for projects/templates
      // configured with the generic email verification type.
      AuthResponse response;
      try {
        response = await _authClient.verifyOTP(
          type: OtpType.signup,
          token: token,
          email: email,
        );
      } on AuthException {
        response = await _authClient.verifyOTP(
          type: OtpType.email,
          token: token,
          email: email,
        );
      }

      _state = _state.copyWith(
        isLoading: false,
        isAuthenticated: response.session != null,
        user: response.user,
        session: response.session,
      );
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('VerifyEmail AuthError: ${e.message}');
      _state = _state.copyWith(
        isLoading: false,
        error: getArabicAuthError(e.message),
      );
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('VerifyEmail UnexpectedError: $e');
      _state = _state.copyWith(
        isLoading: false,
        error: 'حدث خطأ، يرجى المحاولة مرة أخرى',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      await _authClient.resetPasswordForEmail(email);

      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('ResetPassword AuthError: ${e.message}');
      _state = _state.copyWith(
        isLoading: false,
        error: getArabicAuthError(e.message),
      );
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('ResetPassword UnexpectedError: $e');
      _state = _state.copyWith(
        isLoading: false,
        error: 'حدث خطأ، يرجى المحاولة مرة أخرى',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyResetCode(String email, String token) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      final response = await _authClient.verifyOTP(
        type: OtpType.recovery,
        token: token,
        email: email,
      );

      _state = _state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: response.user,
        session: response.session,
      );

      // Sync scores immediately after successful authentication (fire-and-forget)
      unawaited(ScoreRepository().syncScoresWithSupabase());

      // Sync role from auth metadata to profiles table if needed (fire-and-forget)
      unawaited(_syncRoleToProfiles());

      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('VerifyResetCode AuthError: ${e.message}');
      _state = _state.copyWith(
        isLoading: false,
        error: getArabicAuthError(e.message),
      );
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('VerifyResetCode UnexpectedError: $e');
      _state = _state.copyWith(
        isLoading: false,
        error: 'حدث خطأ، يرجى المحاولة مرة أخرى',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      await _authClient.updateUser(UserAttributes(password: newPassword));

      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('UpdatePassword AuthError: ${e.message}');
      _state = _state.copyWith(
        isLoading: false,
        error: getArabicAuthError(e.message),
      );
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('UpdatePassword UnexpectedError: $e');
      _state = _state.copyWith(
        isLoading: false,
        error: 'حدث خطأ، يرجى المحاولة مرة أخرى',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
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
        data['avatar_updated_at'] = DateTime.now().toIso8601String();
        profileUpdate['avatar_url'] = avatarUrl;
      }
      if (grade != null) {
        // Enforce 3-day limit for grade updates
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('grade_updated_at, grade')
            .eq('id', _authClient.currentUser!.id)
            .single();

        final lastUpdate = DateTime.parse(profile['grade_updated_at']);
        final currentGrade = profile['grade'] as int;

        if (currentGrade != grade) {
          final diff = DateTime.now().difference(lastUpdate);
          if (diff.inDays < 3) {
            final remainingInHours = 72 - diff.inHours;
            final remainingInDays = (remainingInHours / 24).ceil();
            _state = _state.copyWith(
              isLoading: false,
              error: 'يمكنك تغيير الصف الدراسي بعد $remainingInDays يوم',
            );
            notifyListeners();
            return false;
          }
          data['grade'] = grade;
          profileUpdate['grade'] = grade;
          profileUpdate['grade_updated_at'] = DateTime.now().toIso8601String();
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

      // 1. Update Profile table first (to catch Unique constraints on username)
      if (profileUpdate.isNotEmpty) {
        await Supabase.instance.client
            .from('profiles')
            .update(profileUpdate)
            .eq('id', _authClient.currentUser!.id);
      }

      // 2. Update Auth Metadata (only non-null values)
      data.removeWhere((_, v) => v == null);
      final response = await _authClient.updateUser(UserAttributes(data: data));

      debugPrint('updateProfile SUCCESS: data=$data');
      _state = _state.copyWith(isLoading: false, user: response.user);
      notifyListeners();
      return true;
    } on PostgrestException catch (e) {
      debugPrint('updateProfile DB error: ${e.message} (code: ${e.code})');
      final errorMsg = getArabicDbError('${e.code} ${e.message}');
      _state = _state.copyWith(isLoading: false, error: errorMsg);
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      debugPrint('UpdateProfile AuthError: ${e.message}');
      _state = _state.copyWith(
        isLoading: false,
        error: getArabicAuthError(e.message),
      );
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('UpdateProfile UnexpectedError: $e');
      _state = _state.copyWith(
        isLoading: false,
        error: 'حدث خطأ في تحديث البيانات',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendOTP(String email, {OtpType type = OtpType.signup}) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      await _authClient.resend(type: type, email: email);

      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('ResendOTP AuthError: ${e.message}');
      _state = _state.copyWith(
        isLoading: false,
        error: getArabicAuthError(e.message),
      );
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('ResendOTP UnexpectedError: $e');
      _state = _state.copyWith(
        isLoading: false,
        error: 'حدث خطأ، يرجى المحاولة مرة أخرى',
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = _authClient.currentUser;
      if (user != null) {
        // Re-fetch user from Supabase auth to get latest metadata
        final response = await _authClient.getUser();
        final updatedUser = response.user ?? user;
        _state = _state.copyWith(user: updatedUser);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('refreshUser error: $e');
    }
  }

  Future<void> _syncRoleToProfiles() async {
    try {
      await Supabase.instance.client.rpc('sync_user_role_to_profiles');
    } catch (e) {
      debugPrint('Role sync error (non-fatal): $e');
    }
  }

  Future<void> loadViolationState() async {
    try {
      final user = _authClient.currentUser;
      if (user == null) return;
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('image_violation_count, image_blocked_until, has_bad_tag, last_violation_at')
          .eq('id', user.id)
          .single();
      _imageViolationCount = profile['image_violation_count'] as int? ?? 0;
      _imageBlockedUntil = profile['image_blocked_until'] != null
          ? DateTime.parse(profile['image_blocked_until'] as String)
          : null;
      _hasBadTag = profile['has_bad_tag'] as bool? ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('loadViolationState error: $e');
    }
  }

  Future<Map<String, dynamic>> uploadAvatar(Uint8List bytes) async {
    final session = _authClient.currentSession;
    if (session == null) {
      return {'error': 'غير مصرح به', 'code': 'UNAUTHORIZED'};
    }

    try {
      final response = await http.post(
        Uri.parse(SupabaseConfig.edgeFunctionUrl),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'image/jpeg',
        },
        body: bytes,
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['status'] == 'accepted') {
        await updateProfile(avatarUrl: data['avatarUrl'] as String?);
        await loadViolationState();
      } else if (response.statusCode == 200 && data['status'] == 'rejected') {
        await loadViolationState();
      }

      return data;
    } on http.ClientException {
      return {'error': 'تعذر الاتصال بالخادم', 'code': 'NETWORK_ERROR'};
    } catch (e) {
      debugPrint('uploadAvatar error: $e');
      return {'error': 'حدث خطأ في رفع الصورة', 'code': 'UPLOAD_ERROR'};
    }
  }

  Future<bool> removeAvatar() async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      // Update profiles table
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': null, 'avatar_updated_at': DateTime.now().toIso8601String()})
          .eq('id', _authClient.currentUser!.id);

      // Update auth metadata
      final response = await _authClient.updateUser(UserAttributes(data: {
        'avatar_url': null,
        'avatar_updated_at': DateTime.now().toIso8601String(),
      }));

      _state = _state.copyWith(isLoading: false, user: response.user);
      notifyListeners();
      return true;
    } on PostgrestException catch (e) {
      debugPrint('removeAvatar DB error: ${e.message} (code: ${e.code})');
      final errorMsg = getArabicDbError('${e.code} ${e.message}');
      _state = _state.copyWith(isLoading: false, error: errorMsg);
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      debugPrint('removeAvatar AuthError: ${e.message}');
      _state = _state.copyWith(
        isLoading: false,
        error: getArabicAuthError(e.message),
      );
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('removeAvatar UnexpectedError: $e');
      _state = _state.copyWith(
        isLoading: false,
        error: 'حدث خطأ في إزالة الصورة',
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authClient.signOut();
    _state = const AuthState();
    _role = null;
    notifyListeners();
  }

  bool get isTeacher {
    final role = _state.user?.userMetadata?['role'] as String? ?? _role;
    return role == 'teacher' || role == 'admin';
  }

  bool get isAdmin {
    final role = _state.user?.userMetadata?['role'] as String? ?? _role;
    return role == 'admin';
  }

  Future<String?> getUserRole() async {
    if (_state.user == null) return null;
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', _state.user!.id)
          .single();
      return response['role'] as String?;
    } catch (e) {
      return _state.user?.userMetadata?['role'] as String?;
    }
  }
}
