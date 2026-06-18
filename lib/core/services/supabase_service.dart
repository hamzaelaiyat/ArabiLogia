import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arabilogia/core/config/supabase_config.dart';
import 'package:arabilogia/core/services/supabase_service_interface.dart';

class SupabaseService implements SupabaseServiceInterface {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  late final SupabaseClient _client;

  @override
  SupabaseClient get client => _client;
  @override
  GoTrueClient get auth => _client.auth;
  @override
  SupabaseQueryBuilder from(String table) => _client.from(table);
  @override
  SupabaseStorageClient get storage => _client.storage;
  @override
  RealtimeClient get realtimeClient => _client.realtime;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      debug: false,
    );
    _client = Supabase.instance.client;
  }

  @override
  PostgrestFilterBuilder<dynamic> rpc(String fn, {Map<String, dynamic>? params}) =>
      _client.rpc(fn, params: params ?? {});

  @override
  User? get currentUser => auth.currentUser;
  @override
  Session? get currentSession => auth.currentSession;

  @override
  bool get isAuthenticated => currentSession != null;

  @override
  String? get userId => currentUser?.id;
  @override
  String? get userEmail => currentUser?.email;

  @override
  Stream<AuthState> get authStateChanges => auth.onAuthStateChange;
}
