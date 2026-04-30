import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arabilogia/core/config/supabase_config.dart';
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
  late final GoTrueClient _auth;

  AuthState _state = const AuthState();
  AuthState get state => _state;

  AuthProvider() {
    try {
      _auth = Supabase.instance.client.auth;
    } catch (e) {
      // Fallback for when Supabase is not initialized yet
      debugPrint('Supabase not initialized: $e');
    }
    if (SupabaseConfig.isConfigured) {
      _init();
    }
  }

  void _init() {
    _state = _state.copyWith(
      isAuthenticated: _auth.currentSession != null,
      user: _auth.currentUser,
      session: _auth.currentSession,
    );

    _auth.onAuthStateChange.listen((event) {
      _state = _state.copyWith(
        isAuthenticated: event.session != null,
        user: event.session?.user,
        session: event.session,
      );
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );

      _state = _state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: response.user,
        session: response.session,
      );

      // Sync scores immediately after successful authentication
      await ScoreRepository().syncScoresWithSupabase();

      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('SignIn AuthError: ${e.message}');
      _state = _state.copyWith(
        isLoading: false,
        error: _getArabicError(e.message),
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

      final response = await _auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'username': username, 'grade': grade},
      );

      _state = _state.copyWith(isLoading: false, user: response.user);

      // Sync scores after signup (especially if they had local scores as anonymous)
      await ScoreRepository().syncScoresWithSupabase();

      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('SignUp AuthError: ${e.message}');
      _state = _state.copyWith(
        isLoading: false,
        error: _getArabicError(e.message),
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
        response = await _auth.verifyOTP(
          type: OtpType.signup,
          token: token,
          email: email,
        );
      } on AuthException {
        response = await _auth.verifyOTP(
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
        error: _getArabicError(e.message),
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

      await _auth.resetPasswordForEmail(email);

      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('ResetPassword AuthError: ${e.message}');
      _state = _state.copyWith(
        isLoading: false,
        error: _getArabicError(e.message),
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

      final response = await _auth.verifyOTP(
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

      // Sync scores immediately after successful authentication
      await ScoreRepository().syncScoresWithSupabase();

      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('VerifyResetCode AuthError: ${e.message}');
      _state = _state.copyWith(
        isLoading: false,
        error: _getArabicError(e.message),
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

      await _auth.updateUser(UserAttributes(password: newPassword));

      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('UpdatePassword AuthError: ${e.message}');
      _state = _state.copyWith(
        isLoading: false,
        error: _getArabicError(e.message),
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
        profileUpdate['avatar_url'] = avatarUrl;
      }
      if (grade != null) {
        // Enforce 3-day limit for grade updates
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('grade_updated_at, grade')
            .eq('id', _auth.currentUser!.id)
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
        data['hide_avatar'] = hideAvatar;
        profileUpdate['hide_avatar'] = hideAvatar;
      }
      if (notifications != null) {
        data['notifications'] = notifications;
      }

      // 1. Update Profile table first (to catch Unique constraints on username)
      if (profileUpdate.isNotEmpty) {
        await Supabase.instance.client
            .from('profiles')
            .update(profileUpdate)
            .eq('id', _auth.currentUser!.id);
      }

      // 2. Update Auth Metadata
      final response = await _auth.updateUser(UserAttributes(data: data));

      _state = _state.copyWith(isLoading: false, user: response.user);
      notifyListeners();
      return true;
    } on PostgrestException catch (e) {
      debugPrint('Profile update DB error: ${e.message}');
      String errorMsg = 'حدث خطأ في تحديث البيانات';
      if (e.message.contains('unique constraint') ||
          e.message.contains('username')) {
        errorMsg = 'اسم المستخدم هذا مستخدم بالفعل، اختر اسماً آخر';
      }
      _state = _state.copyWith(isLoading: false, error: errorMsg);
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      debugPrint('UpdateProfile AuthError: ${e.message}');
      _state = _state.copyWith(
        isLoading: false,
        error: _getArabicError(e.message),
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

      await _auth.resend(type: type, email: email);

      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('ResendOTP AuthError: ${e.message}');
      _state = _state.copyWith(
        isLoading: false,
        error: _getArabicError(e.message),
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

  Future<void> signOut() async {
    await _auth.signOut();
    _state = const AuthState();
    notifyListeners();
  }

  bool get isTeacher {
    final role = _state.user?.userMetadata?['role'] as String?;
    return role == 'teacher' || role == 'admin';
  }

  bool get isAdmin {
    return _state.user?.userMetadata?['role'] == 'admin';
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

  String _getArabicError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'بيانات الدخول غير صحيحة';
    } else if (message.contains('Email not confirmed')) {
      return 'يرجى تأكيد البريد الإلكتروني';
    } else if (message.contains('User already registered')) {
      return 'البريد الإلكتروني مستخدم بالفعل';
    } else if (message.contains('Password should be at least')) {
      return 'كلمة المرور ضعيفة جداً';
    } else if (message.contains('Invalid email')) {
      return 'البريد الإلكتروني غير صالح';
    }
    return message;
  }
}
