import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:http/http.dart' as http;
import 'package:arabilogia/core/config/supabase_config.dart';
import 'package:arabilogia/core/routes/app_router.dart';
import 'package:arabilogia/core/services/auth_service.dart';
import 'package:arabilogia/core/services/profile_service.dart';
import 'package:arabilogia/core/services/avatar_service.dart';
import 'package:arabilogia/core/services/supabase_service.dart';
import 'package:arabilogia/core/utils/auth_error_mapper.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/features/auth/providers/auth_state.dart';

class AuthProvider extends ChangeNotifier {
  GoTrueClient? _auth;
  late final AuthService _authService;
  late final ProfileService _profileService;
  late final AvatarService _avatarService;

  AuthState _state = const AuthState();
  AuthState get state => _state;

  String? _role;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ---------------------------------------------------------------------------
  // Violation state
  // ---------------------------------------------------------------------------

  int _imageViolationCount = 0;
  DateTime? _imageBlockedUntil;
  bool _hasBadTag = false;

  bool get canUploadAvatar =>
      !_hasBadTag &&
      (_imageBlockedUntil == null ||
          _imageBlockedUntil!.isBefore(DateTime.now()));
  int get imageViolationCount => _imageViolationCount;
  DateTime? get imageBlockedUntil => _imageBlockedUntil;
  bool get hasBadTag => _hasBadTag;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  GoTrueClient get _authClient {
    _auth ??= Supabase.instance.client.auth;
    return _auth!;
  }

  AuthProvider();

  void _initServices() {
    final supabase = SupabaseService.instance;
    _authService = AuthService(supabase);
    _profileService = ProfileService(supabase);
    _avatarService = AvatarService(supabase, http.Client());
  }

  Future<void> initializeAfterSupabase() async {
    try {
      if (!SupabaseConfig.isConfigured) {
        _isInitialized = true;
        notifyListeners();
        return;
      }

      await SupabaseService.instance.initialize();
      _initServices();
      _auth = Supabase.instance.client.auth;
      _state = _state.copyWith(
        isAuthenticated: _auth!.currentSession != null,
        user: _auth!.currentUser,
        session: _auth!.currentSession,
      );

      if (_auth!.currentSession != null) {
        await Future.wait([
          _loadViolationState(),
          _syncRoleFromDb(),
        ]);
      }

      _auth!.onAuthStateChange.listen((event) async {
        _state = _state.copyWith(
          isAuthenticated: event.session != null,
          user: event.session?.user,
          session: event.session,
        );
        if (event.session != null) {
          await Future.wait([
            _loadViolationState(),
            _syncRoleFromDb(),
          ]);
        } else {
          _role = null;
        }
        notifyListeners();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppRouter.router.refresh();
        });
      });
    } catch (e) {
      debugPrint('Error initializing AuthProvider: $e');
    }

    _isInitialized = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  Future<bool> signIn(String email, String password) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null, fieldErrors: {});
      notifyListeners();

      final result = await _authService.signIn(email, password);

      _state = _state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: result.user,
        session: result.session,
      );

      await _syncRoleFromDb();

      unawaited(ScoreRepository().syncScoresWithSupabase());

      notifyListeners();
      return true;
    } on AuthException catch (e) {
      final fieldError = getArabicAuthFieldError(e.message);
      _state = _state.copyWith(
        isLoading: false,
        error: fieldError.message,
        fieldErrors: fieldError.field != null
            ? {fieldError.field!: fieldError.message}
            : {},
      );
      notifyListeners();
      return false;
    } catch (e) {
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
      _state = _state.copyWith(isLoading: true, error: null, fieldErrors: {});
      notifyListeners();

      final result = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        username: username,
        grade: grade,
      );

      if (result.alreadyExists) {
        _state = _state.copyWith(
          isLoading: false,
          error: 'لديك حساب بالفعل، يرجى تسجيل الدخول',
          fieldErrors: {'email': 'لديك حساب بالفعل، يرجى تسجيل الدخول'},
        );
        notifyListeners();
        return false;
      }

      _state = _state.copyWith(isLoading: false, user: result.user);
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      final fieldError = getArabicAuthFieldError(e.message);
      _state = _state.copyWith(
        isLoading: false,
        error: fieldError.message,
        fieldErrors: fieldError.field != null
            ? {fieldError.field!: fieldError.message}
            : {},
      );
      notifyListeners();
      return false;
    } catch (e) {
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

      final result = await _authService.verifyEmail(email, token);

      _state = _state.copyWith(
        isLoading: false,
        isAuthenticated: result.isAuthenticated,
        user: result.user,
        session: result.session,
      );

      if (result.isAuthenticated) {
        await _syncRoleFromDb();
      }

      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: getArabicAuthError(e.message),
      );
      notifyListeners();
      return false;
    } catch (e) {
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

      await _authService.resetPassword(email);

      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: getArabicAuthError(e.message),
      );
      notifyListeners();
      return false;
    } catch (e) {
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

      final result = await _authService.verifyResetCode(email, token);

      _state = _state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: result.user,
        session: result.session,
      );

      await _syncRoleFromDb();

      unawaited(ScoreRepository().syncScoresWithSupabase());

      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: getArabicAuthError(e.message),
      );
      notifyListeners();
      return false;
    } catch (e) {
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

      await _authService.updatePassword(newPassword);

      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: getArabicAuthError(e.message),
      );
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'حدث خطأ، يرجى المحاولة مرة أخرى',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendOTP(String email, {OtpType type = OtpType.signup}) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      await _authService.resendOTP(email, type: type);

      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: getArabicAuthError(e.message),
      );
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'حدث خطأ، يرجى المحاولة مرة أخرى',
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _state = const AuthState();
    _role = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  Future<bool> updateProfile({
    String? fullName,
    String? username,
    String? avatarUrl,
    int? grade,
    String? description,
    bool? isPublic,
    bool? hideAvatar,
    bool? hideName,
    String? randomName,
    Map<String, bool>? notifications,
  }) async {
    final oldUser = _state.user;

    User? optimisticUser;
    if (oldUser != null) {
      final metadata = Map<String, dynamic>.from(oldUser.userMetadata ?? {});
      bool changed = false;
      if (fullName != null) {
        metadata['full_name'] = fullName;
        changed = true;
      }
      if (username != null) {
        metadata['username'] = username;
        changed = true;
      }
      if (grade != null) {
        metadata['grade'] = grade;
        changed = true;
      }
      if (avatarUrl != null) {
        metadata['avatar_url'] = avatarUrl;
        changed = true;
      }
      if (description != null) {
        metadata['description'] = description;
        changed = true;
      }
      if (changed) {
        final json = oldUser.toJson();
        json['user_metadata'] = metadata;
        optimisticUser = User.fromJson(json);
      }
    }

    _state = _state.copyWith(
      isLoading: true,
      error: null,
      user: optimisticUser ?? _state.user,
    );
    notifyListeners();

    final result = await _profileService.updateProfile(
      userId: _authClient.currentUser!.id,
      fullName: fullName,
      username: username,
      avatarUrl: avatarUrl,
      grade: grade,
      description: description,
      isPublic: isPublic,
      hideAvatar: hideAvatar,
      hideName: hideName,
      randomName: randomName,
      notifications: notifications,
    );

    _state = _state.copyWith(
      isLoading: false,
      user:
          result.user ??
          (result.success
              ? (optimisticUser ?? _state.user)
              : oldUser ?? _state.user),
      error: result.error,
    );
    notifyListeners();
    return result.success;
  }

  Future<void> refreshUser() async {
    final updatedUser = await _profileService.refreshUser();
    if (updatedUser != null) {
      _state = _state.copyWith(user: updatedUser);
      notifyListeners();
    }
  }

  Future<String?> getUserRole() async {
    return _profileService.getUserRole();
  }

  // ---------------------------------------------------------------------------
  // Avatar
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> uploadAvatar(Uint8List bytes) async {
    final session = _authClient.currentSession;
    if (session == null) {
      return {'error': 'غير مصرح به', 'code': 'UNAUTHORIZED'};
    }

    final result = await _avatarService.uploadAvatar(bytes);

    if (result.accepted && result.avatarUrl != null) {
      await updateProfile(avatarUrl: result.avatarUrl);
      await _loadViolationState();
    } else if (result.rejected) {
      await _loadViolationState();
    }

    if (result.accepted) {
      return {'status': 'accepted', 'avatarUrl': result.avatarUrl};
    } else if (result.rejected) {
      return {'status': 'rejected'};
    }
    return {'error': result.error, 'code': result.code ?? 'ERROR'};
  }

  Future<bool> removeAvatar() async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      final result = await _avatarService.removeAvatar(
        _authClient.currentUser!.id,
      );

      _state = _state.copyWith(
        isLoading: false,
        user: result.user ?? _state.user,
        error: result.error,
      );
      notifyListeners();
      return result.success;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'حدث خطأ في إزالة الصورة',
      );
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Violations (internal)
  // ---------------------------------------------------------------------------

  Future<void> _loadViolationState() async {
    final state = await _profileService.loadViolationState();
    _imageViolationCount = state.imageViolationCount;
    _imageBlockedUntil = state.imageBlockedUntil;
    _hasBadTag = state.hasBadTag;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Role helpers
  // ---------------------------------------------------------------------------

  Future<void> _syncRoleFromDb() async {
    _role = await _profileService.getUserRole();
  }

  bool get isTeacher {
    final effectiveRole =
        _role ?? _state.user?.userMetadata?['role'] as String?;
    return effectiveRole == 'teacher' || effectiveRole == 'admin';
  }

  bool get isAdmin {
    final effectiveRole =
        _role ?? _state.user?.userMetadata?['role'] as String?;
    return effectiveRole == 'admin';
  }
}
