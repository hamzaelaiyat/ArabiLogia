import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SupabaseServiceInterface {
  SupabaseClient get client;
  RealtimeClient get realtimeClient;
  GoTrueClient get auth;
  SupabaseQueryBuilder from(String table);
  SupabaseStorageClient get storage;
  PostgrestFilterBuilder<dynamic> rpc(String fn, {Map<String, dynamic>? params});
  User? get currentUser;
  Session? get currentSession;
  bool get isAuthenticated;
  String? get userId;
  String? get userEmail;
  Stream<AuthState> get authStateChanges;
}
