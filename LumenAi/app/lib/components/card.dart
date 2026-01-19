import 'package:flutter/material.dart';

class Flashcard extends StatelessWidget {
  final String text;
  final bool isFront;
  final bool hasAudio;

  const Flashcard({super.key, required this.text, required this.isFront, required this.hasAudio});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: .2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isFront ? "TERM" : "DEFINITION",
              style: const TextStyle(color: Colors.white54, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),

            if (hasAudio) 
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 28,
                ),
            ),

            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text("Tap to flip", style: TextStyle(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}
