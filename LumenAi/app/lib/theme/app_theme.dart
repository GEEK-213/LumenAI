import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  final String id;
  final String name;
  final ThemeData themeData;

  AppTheme({required this.id, required this.name, required this.themeData});

  static final ThemeData _defaultDark = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF0C1223),
    cardColor: const Color(0xFF1A2036),
    bottomAppBarTheme: const BottomAppBarThemeData(color: Color(0xFF050B18)),
    primaryColor: const Color(0xFF1E88E5),
    colorScheme: const ColorScheme.dark().copyWith(
      primary: const Color(0xFF1E88E5),
      secondary: const Color(0xFF1E88E5),
      // Restored default surface to standard M3 dark mode back to avoid breaking anything else
      surface: const Color(0xFF1E1E1E),
    ),
  );

  static final List<AppTheme> themes = [
    AppTheme(id: 'default', name: 'Default Dark', themeData: _defaultDark),
    AppTheme(
      id: 'theme_synthwave',
      name: 'Synthwave / Cyberpunk',
      themeData: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0221),
        cardColor: const Color(0xFF1B093C),
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Color(0xFF060111),
        ),
        primaryColor: const Color(0xFFFF007F), // Neon Pink
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFFFF007F),
          secondary: const Color(0xFF00FFCC), // Neon Cyan
          surface: const Color(0xFF1B093C),
        ),
      ),
    ),
    AppTheme(
      id: 'theme_sunset',
      name: 'Sunset Warm',
      themeData: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFFFF3E0),
        cardColor: Colors.white,
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Color(0xFFFFE0B2),
        ),
        primaryColor: const Color(0xFFFF7043),
        colorScheme: const ColorScheme.light().copyWith(
          primary: const Color(0xFFFF7043),
          secondary: const Color(0xFFFFCA28),
          surface: const Color(0xFFFFE0B2),
        ),
      ),
    ),
    AppTheme(
      id: 'theme_crimson',
      name: 'Crimson Tech',
      themeData: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Color(0xFF000000),
        ),
        primaryColor: const Color(0xFFD32F2F),
        textTheme: GoogleFonts.shareTechMonoTextTheme(
          ThemeData.dark().textTheme,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E1E1E),
          elevation: 0,
          shape: BeveledRectangleBorder(
            side: BorderSide(color: Color(0xFFD32F2F), width: 1.5),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1A1A1A),
          shape: BeveledRectangleBorder(
            side: BorderSide(color: Color(0xFFD32F2F), width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            shape: const BeveledRectangleBorder(
              side: BorderSide(color: Color(0xFFD32F2F), width: 1.5),
            ),
          ),
        ),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFFD32F2F),
          secondary: const Color(0xFFFF5252),
          surface: const Color(0xFF1E1E1E),
        ),
      ),
    ),
    AppTheme(
      id: 'theme_sketch',
      name: 'Sketchbook',
      themeData: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        cardColor: Colors.white,
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Color(0xFFF0F0F0),
        ),
        primaryColor: const Color(0xFF69F0AE), // Mint
        textTheme: GoogleFonts.comicNeueTextTheme(ThemeData.light().textTheme),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 4,
          shadowColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: Colors.black, width: 2),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            side: BorderSide(color: Colors.black, width: 2),
          ),
        ),
        colorScheme: const ColorScheme.light().copyWith(
          primary: const Color(0xFF69F0AE),
          secondary: const Color(0xFF40C4FF),
          surface: Colors.white,
        ),
      ),
    ),
    AppTheme(
      id: 'theme_noir',
      name: 'Noir Minimal',
      themeData: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        cardColor: const Color(0xFF2C2C2E),
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Color(0xFF121212),
        ),
        primaryColor: const Color(0xFFC0A080), // Muted Gold
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFFC0A080),
          secondary: const Color(0xFF8E8E93),
          surface: const Color(0xFF2C2C2E),
        ),
      ),
    ),
  ];

  static ThemeData getThemeById(String id) {
    return themes
        .firstWhere((t) => t.id == id, orElse: () => themes.first)
        .themeData;
  }
}
