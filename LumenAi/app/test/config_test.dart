import 'package:flutter_test/flutter_test.dart';
import 'package:app/config.dart';

/// Tests for the AppConfig centralized configuration.
void main() {
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
