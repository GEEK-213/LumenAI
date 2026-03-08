import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration for LumenAI.
///
/// Secrets are loaded from the .env file using flutter_dotenv.
class AppConfig {
  /// Supabase project URL
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://knonzasojytvmxhkchvg.supabase.co';

  /// Supabase anonymous (publishable) key
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Backend API base URL
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ??
      'https://graeme-weathered-jackie.ngrok-free.dev';
}
