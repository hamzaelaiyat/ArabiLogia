import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final Session? session;
  final String? error;
  final Map<String, String> fieldErrors;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.session,
    this.error,
    this.fieldErrors = const {},
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    Session? session,
    String? error,
    Map<String, String>? fieldErrors,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      session: session ?? this.session,
      error: error,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}
