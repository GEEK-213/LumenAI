import 'package:flutter/material.dart';

class Flashcard extends StatelessWidget {
  final String text;
  final bool isFront;
  final bool hasAudio;
  final bool isPlaying;
  final VoidCallback? onPlay;

  const Flashcard({
    super.key,
    required this.text,
    required this.isFront,
    required this.hasAudio,
    required this.isPlaying,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: .18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFront ? "TERM" : "DEFINITION",
                style: const TextStyle(
                  color: Color.fromARGB(181, 255, 255, 255),
                  letterSpacing: 1.2,
                  fontSize: 15,
                ),
              ),
              if (hasAudio)
                AnimatedScale(
                  scale: isPlaying ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  child: IconButton(
                    icon: Icon(
                      Icons.volume_up,
                      color: isPlaying
                          ? Colors.white
                          : Colors.white.withValues(alpha: .7),
                      size: 22,
                    ),
                    onPressed: onPlay,
                  ),
                ),
            ],
          ),

          Expanded(
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const Text(
            "Tap to flip",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color.fromARGB(131, 255, 255, 255),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
