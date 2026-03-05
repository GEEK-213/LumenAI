/// Centralized configuration for LumenAI.
///
/// Secrets are injected at compile time via --dart-define flags:
///   flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=...
///
/// For development, fallback values are provided. In production builds,
/// ALWAYS supply these via --dart-define to avoid shipping secrets in source.
class AppConfig {
  /// Supabase project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://knonzasojytvmxhkchvg.supabase.co',
  );

  /// Supabase anonymous (publishable) key
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtub256YXNvanl0dm14aGtjaHZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY2NTU4NTIsImV4cCI6MjA4MjIzMTg1Mn0.WnxSictcwfY-1xBH8pHGVczR2BO_ArddpQpR4yCgc-I',
  );

  /// Backend API base URL
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://graeme-weathered-jackie.ngrok-free.dev',
  );
}
