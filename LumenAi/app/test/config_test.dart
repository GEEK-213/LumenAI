import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app/config.dart';

/// Tests for the AppConfig centralized configuration.
void main() {
  setUpAll(() {
    dotenv.env.addAll({
      'SUPABASE_URL': 'https://test.supabase.co',
      'SUPABASE_ANON_KEY':
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.y_test_very_long_string_123456789012345678901234567890',
      'API_BASE_URL': 'http://localhost:8001',
    });
  });

  group('AppConfig', () {
    test('supabaseUrl has a non-empty default value', () {
      expect(AppConfig.supabaseUrl, isNotEmpty);
      expect(AppConfig.supabaseUrl, contains('supabase.co'));
    });

    test('supabaseAnonKey has a non-empty default value', () {
      expect(AppConfig.supabaseAnonKey, isNotEmpty);
      expect(AppConfig.supabaseAnonKey.length, greaterThan(50));
    });

    test('apiBaseUrl has a default value', () {
      expect(AppConfig.apiBaseUrl, isNotEmpty);
    });

    test('supabaseUrl is a valid URL format', () {
      expect(AppConfig.supabaseUrl, startsWith('http'));
    });
  });
}
