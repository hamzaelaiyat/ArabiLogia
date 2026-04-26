import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arabilogia/core/config/supabase_config.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  late final SupabaseClient _client;

  SupabaseClient get client => _client;
  GoTrueClient get auth => _client.auth;
  SupabaseQueryBuilder from(String table) => _client.from(table);
  SupabaseStorageClient get storage => _client.storage;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      debug: false,
    );
    _client = Supabase.instance.client;
  }

  User? get currentUser => auth.currentUser;
  Session? get currentSession => auth.currentSession;

  bool get isAuthenticated => currentSession != null;

  String? get userId => currentUser?.id;
  String? get userEmail => currentUser?.email;

  Stream<AuthState> get authStateChanges => auth.onAuthStateChange;
}
