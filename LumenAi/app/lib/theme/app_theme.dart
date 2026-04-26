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
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        cardColor: const Color(0xFF141414),
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Color(0xFF000000),
        ),
        primaryColor: const Color(0xFFD32F2F),
        textTheme: GoogleFonts.shareTechMonoTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
        dividerColor: const Color(0xFF2A2A2A),
        // AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0A0A0A),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.shareTechMono(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        // Card
        cardTheme: const CardThemeData(
          color: Color(0xFF141414),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Color(0xFF333333), width: 1.0),
            borderRadius: BorderRadius.zero,
          ),
        ),
        // FAB
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFD32F2F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 0,
        ),
        // Elevated Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            textStyle: GoogleFonts.shareTechMono(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        // Text Buttons
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFD32F2F),
            textStyle: GoogleFonts.shareTechMono(),
          ),
        ),
        // Outlined Buttons
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF555555), width: 1.0),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            textStyle: GoogleFonts.shareTechMono(),
          ),
        ),
        // Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF141414),
          hintStyle: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 14),
          labelStyle: GoogleFonts.shareTechMono(color: const Color(0xFFD32F2F), fontSize: 14),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFF333333)),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFF333333)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFFD32F2F), width: 1.5),
          ),
        ),
        // Dialog
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF0A0A0A),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Color(0xFF333333), width: 1.0),
          ),
          titleTextStyle: GoogleFonts.shareTechMono(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        // BottomSheet
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF0A0A0A),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Color(0xFF333333), width: 1.0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
          ),
        ),
        // TabBar
        tabBarTheme: TabBarThemeData(
          labelColor: const Color(0xFFD32F2F),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFFD32F2F),
          labelStyle: GoogleFonts.shareTechMono(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 1.0,
          ),
          unselectedLabelStyle: GoogleFonts.shareTechMono(
            fontSize: 13,
            letterSpacing: 1.0,
          ),
        ),
        // Bottom Navigation
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF000000),
          indicatorColor: const Color(0xFFD32F2F).withOpacity(0.2),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFFD32F2F));
            }
            return const IconThemeData(color: Colors.white54);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.shareTechMono(
                color: const Color(0xFFD32F2F),
                fontSize: 11,
              );
            }
            return GoogleFonts.shareTechMono(
              color: Colors.white54,
              fontSize: 11,
            );
          }),
        ),
        // NavigationRail
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: const Color(0xFF000000),
          indicatorColor: const Color(0xFFD32F2F).withOpacity(0.2),
          selectedIconTheme: const IconThemeData(color: Color(0xFFD32F2F)),
          unselectedIconTheme: const IconThemeData(color: Colors.white54),
          selectedLabelTextStyle: GoogleFonts.shareTechMono(
            color: const Color(0xFFD32F2F),
            fontSize: 11,
          ),
          unselectedLabelTextStyle: GoogleFonts.shareTechMono(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
        // SnackBar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1A1A1A),
          contentTextStyle: GoogleFonts.shareTechMono(color: Colors.white),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Color(0xFFD32F2F)),
          ),
        ),
        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF141414),
          selectedColor: const Color(0xFFD32F2F),
          labelStyle: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 12),
          side: const BorderSide(color: Color(0xFF333333)),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        // Progress
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFFD32F2F),
          linearTrackColor: Color(0xFF333333),
        ),
        // ColorScheme
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFFD32F2F),
          secondary: const Color(0xFFFF5252),
          surface: const Color(0xFF141414),
          onSurface: Colors.white,
          onPrimary: Colors.white,
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
