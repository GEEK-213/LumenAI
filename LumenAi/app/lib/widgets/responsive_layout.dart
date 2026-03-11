import 'package:flutter/material.dart';

/// Breakpoints for responsive layout
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Returns true if the screen is wide enough for desktop layout
bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= Breakpoints.tablet;

/// Returns true if the screen is wide enough for split-screen
bool isWideScreen(BuildContext context) =>
    MediaQuery.of(context).size.width >= Breakpoints.desktop;

/// Adaptive layout that shows different UIs based on screen width.
/// - mobile: shows [mobileBody] only
/// - tablet/desktop: shows [sidePanel] + [mobileBody] side by side
class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget? sidePanel;
  final double sidePanelWidth;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    this.sidePanel,
    this.sidePanelWidth = 320,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= Breakpoints.desktop && sidePanel != null) {
      // Desktop: side panel + main content
      return Row(
        children: [
          SizedBox(width: sidePanelWidth, child: sidePanel!),
          VerticalDivider(width: 1, color: Colors.white.withOpacity(0.08)),
          Expanded(child: mobileBody),
        ],
      );
    }

    // Mobile / Tablet: single column
    return mobileBody;
  }
}
