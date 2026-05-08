import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static String get supabaseUrl {
    try {
      return dotenv.get('SUPABASE_URL', fallback: 'https://placeholder.supabase.co');
    } catch (e) {
      return 'https://placeholder.supabase.co';
    }
  }

  static String get supabaseAnonKey {
    try {
      return dotenv.get('SUPABASE_ANON_KEY', fallback: 'placeholder');
    } catch (e) {
      return 'placeholder';
    }
  }

  static bool get isConfigured =>
      supabaseUrl != 'https://placeholder.supabase.co' &&
      supabaseAnonKey != 'placeholder';
}
