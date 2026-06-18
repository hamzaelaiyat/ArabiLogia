import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arabilogia/core/services/supabase_service_interface.dart';

class SignInResult {
  final User user;
  final Session session;
  const SignInResult({required this.user, required this.session});
}

class SignUpResult {
  final User? user;
  const SignUpResult({this.user});
  bool get alreadyExists => user == null;
}

class VerifyEmailResult {
  final User? user;
  final Session? session;
  const VerifyEmailResult({this.user, this.session});
  bool get isAuthenticated => session != null;
}

class VerifyResetCodeResult {
  final User user;
  final Session session;
  const VerifyResetCodeResult({required this.user, required this.session});
}

class AuthService {
  final SupabaseServiceInterface _supabase;
  GoTrueClient get _auth => _supabase.auth;

  AuthService(this._supabase);

  Future<SignInResult> signIn(String email, String password) async {
    final response = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null || response.session == null) {
      throw const AuthException('Invalid login credentials');
    }
    return SignInResult(user: response.user!, session: response.session!);
  }

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required int grade,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'username': username, 'grade': grade},
      );
      return SignUpResult(user: response.user);
    } on AuthException catch (e) {
      if (e.message.contains('already') || e.message.contains('exists')) {
        return const SignUpResult();
      }
      rethrow;
    }
  }

  Future<VerifyEmailResult> verifyEmail(String email, String token) async {
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
    return VerifyEmailResult(user: response.user, session: response.session);
  }

  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  Future<VerifyResetCodeResult> verifyResetCode(
      String email, String token) async {
    final response = await _auth.verifyOTP(
      type: OtpType.recovery,
      token: token,
      email: email,
    );
    if (response.user == null || response.session == null) {
      throw const AuthException('Invalid or expired reset code');
    }
    return VerifyResetCodeResult(
      user: response.user!,
      session: response.session!,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> resendOTP(String email, {OtpType type = OtpType.signup}) async {
    await _auth.resend(type: type, email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
