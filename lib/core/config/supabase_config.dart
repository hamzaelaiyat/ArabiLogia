import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Client-side Supabase configuration.
///
/// Both values are public by design: the anon key is protected by Row Level
/// Security. They are read in this order:
///
/// 1. Compile-time values injected with `--dart-define` (used by the web build).
/// 2. The bundled `.env` asset (used by local runs and mobile builds).
/// 3. A placeholder, which leaves the app in a safe unconfigured state.
///
/// The compile-time step exists because the web host strips dotfiles: a request
/// for `assets/.env` returns `index.html` instead of the file, so `dotenv` is
/// empty on the deployed site. Without the defines the web app would boot
/// against `placeholder.supabase.co`.
class SupabaseConfig {
  SupabaseConfig._();

  static const String placeholderUrl = 'https://placeholder.supabase.co';
  static const String placeholderAnonKey = 'placeholder';

  static const String _compiledUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _compiledAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static String get supabaseUrl {
    if (_compiledUrl.isNotEmpty) return _compiledUrl;
    return _fromDotEnv('SUPABASE_URL', placeholderUrl);
  }

  static String get supabaseAnonKey {
    if (_compiledAnonKey.isNotEmpty) return _compiledAnonKey;
    return _fromDotEnv('SUPABASE_ANON_KEY', placeholderAnonKey);
  }

  static String get edgeFunctionUrl => '$supabaseUrl/functions/v1/mod-avatars';

  static bool get isConfigured =>
      supabaseUrl != placeholderUrl && supabaseAnonKey != placeholderAnonKey;

  static String _fromDotEnv(String key, String fallback) {
    try {
      final value = dotenv.get(key, fallback: fallback);
      return value.isEmpty ? fallback : value;
    } catch (_) {
      return fallback;
    }
  }
}
