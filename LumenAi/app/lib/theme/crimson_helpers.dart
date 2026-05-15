import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

/// Utility helpers for the Crimson Tech theme.
/// Use `CrimsonHelpers.isCrimson(context)` to conditionally apply
/// terminal-style UI elements.
class CrimsonHelpers {
  static const Color crimsonRed = Color(0xFFFF003C);
  static const Color crimsonBg = Color(0xFF0A0A0A);
  static const Color crimsonCard = Color(0xFF141414);
  static const Color crimsonBorder = Color(0xFF333333);

  /// Returns true when the Crimson Tech theme is currently equipped.
  static bool isCrimson(BuildContext context) {
    try {
      return Provider.of<ThemeProvider>(context, listen: false)
              .currentThemeId ==
          'theme_crimson';
    } catch (_) {
      return false;
    }
  }

  /// Builds a "SYSTEM//LABEL" + "TITLE" header in monospace.
  static Widget systemHeader(String systemLabel, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'SYSTEM//$systemLabel',
          style: GoogleFonts.shareTechMono(
            color: crimsonRed,
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.teko(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  /// Section heading with red accent bar on the left.
  static Widget sectionHeading(String text) {
    return Row(
      children: [
        Container(width: 3, height: 18, color: crimsonRed),
        const SizedBox(width: 10),
        Text(
          text.toUpperCase().replaceAll(' ', '_'),
          style: GoogleFonts.shareTechMono(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  /// A bordered container with the Crimson Tech terminal look.
  static Widget borderedContainer({
    required Widget child,
    Color? borderColor,
    EdgeInsets padding = const EdgeInsets.all(16),
    EdgeInsets margin = EdgeInsets.zero,
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: crimsonCard,
        border: Border.all(
          color: borderColor ?? crimsonBorder,
          width: 1.0,
        ),
      ),
      child: child,
    );
  }

  /// Monospace Text widget styled for Crimson Tech.
  static Text monoText(
    String text, {
    Color color = Colors.white,
    double size = 14,
    FontWeight weight = FontWeight.normal,
  }) {
    return Text(
      text,
      style: GoogleFonts.shareTechMono(
        color: color,
        fontSize: size,
        fontWeight: weight,
      ),
    );
  }

  /// Returns the Crimson-styled AppBar title widget.
  /// Use this in AppBar's `title` parameter when Crimson is active.
  static Widget appBarTitle(String systemLabel, String title) {
    return systemHeader(systemLabel, title);
  }
}
