import 'package:flutter/material.dart';
import '../services/gamification_service.dart';
import 'app_theme.dart';

class ThemeProvider with ChangeNotifier {
  String _currentThemeId = 'default';
  bool _isLoading = true;
  final GamificationService _gamificationService = GamificationService();

  String get currentThemeId => _currentThemeId;
  ThemeData get currentThemeData => AppTheme.getThemeById(_currentThemeId);
  bool get isLoading => _isLoading;

  ThemeProvider() {
    loadTheme();
  }

  Future<void> loadTheme() async {
    _isLoading = true;
    notifyListeners();
    try {
      final profile = await _gamificationService.fetchProfile();
      final equipped = profile['equipped_theme'] as String?;
      if (equipped != null && equipped.isNotEmpty) {
        _currentThemeId = equipped;
      }
    } catch (e) {
      debugPrint("Error loading equipped theme: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setEquippedTheme(String themeId) async {
    if (_currentThemeId == themeId) return;

    // Optimistic UI update
    final previousThemeId = _currentThemeId;
    _currentThemeId = themeId;
    notifyListeners();

    try {
      final success = await _gamificationService.equipTheme(themeId);
      if (!success) {
        // Rollback
        _currentThemeId = previousThemeId;
        notifyListeners();
      }
    } catch (e) {
      _currentThemeId = previousThemeId;
      notifyListeners();
      debugPrint("Error saving theme: $e");
    }
  }
}
