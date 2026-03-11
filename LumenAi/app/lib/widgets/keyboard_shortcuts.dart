import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps a child widget with keyboard shortcuts for study interactions.
///
/// Supported shortcuts:
/// - Arrow left/right: navigate flashcards
/// - Space: flip flashcard
/// - 1-4: select quiz answer
/// - Enter: submit quiz answer
class KeyboardShortcutWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onLeft;
  final VoidCallback? onRight;
  final VoidCallback? onSpace;
  final ValueChanged<int>? onNumberKey; // 1-4
  final VoidCallback? onEnter;

  const KeyboardShortcutWrapper({
    super.key,
    required this.child,
    this.onLeft,
    this.onRight,
    this.onSpace,
    this.onNumberKey,
    this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowLeft:
            if (onLeft != null) {
              onLeft!();
              return KeyEventResult.handled;
            }
          case LogicalKeyboardKey.arrowRight:
            if (onRight != null) {
              onRight!();
              return KeyEventResult.handled;
            }
          case LogicalKeyboardKey.space:
            if (onSpace != null) {
              onSpace!();
              return KeyEventResult.handled;
            }
          case LogicalKeyboardKey.enter:
            if (onEnter != null) {
              onEnter!();
              return KeyEventResult.handled;
            }
          case LogicalKeyboardKey.digit1:
          case LogicalKeyboardKey.numpad1:
            if (onNumberKey != null) {
              onNumberKey!(0);
              return KeyEventResult.handled;
            }
          case LogicalKeyboardKey.digit2:
          case LogicalKeyboardKey.numpad2:
            if (onNumberKey != null) {
              onNumberKey!(1);
              return KeyEventResult.handled;
            }
          case LogicalKeyboardKey.digit3:
          case LogicalKeyboardKey.numpad3:
            if (onNumberKey != null) {
              onNumberKey!(2);
              return KeyEventResult.handled;
            }
          case LogicalKeyboardKey.digit4:
          case LogicalKeyboardKey.numpad4:
            if (onNumberKey != null) {
              onNumberKey!(3);
              return KeyEventResult.handled;
            }
        }

        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

/// A helper that shows keyboard shortcut hints on desktop/web.
class ShortcutHintBar extends StatelessWidget {
  final List<ShortcutHint> hints;

  const ShortcutHintBar({super.key, required this.hints});

  @override
  Widget build(BuildContext context) {
    // Only show on desktop-ish widths
    if (MediaQuery.of(context).size.width < 800) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: hints
            .map(
              (h) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Text(
                        h.key,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      h.label,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class ShortcutHint {
  final String key;
  final String label;
  const ShortcutHint(this.key, this.label);
}
