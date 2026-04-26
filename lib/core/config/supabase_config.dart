import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static String get supabaseUrl =>
      dotenv.get('SUPABASE_URL', fallback: 'https://placeholder.supabase.co');

  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: 'placeholder');

  static bool get isConfigured =>
      supabaseUrl != 'https://placeholder.supabase.co' &&
      supabaseAnonKey != 'placeholder';
}
