import 'package:flutter/material.dart';

class AudioPlayerUI extends StatelessWidget {
  final bool isPlaying;
  final double progress;
  final VoidCallback onPlayPause;

  const AudioPlayerUI({
    super.key,
    required this.isPlaying,
    required this.progress,
    required this.onPlayPause,
    });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: .15)
      ),
      child: Column(
        children: [
          IconButton(
            iconSize: 48, 
            onPressed: onPlayPause, 
            icon: Icon(
              isPlaying 
              ? Icons.pause_circle 
              : Icons.play_circle
              ),
            ),
            const SizedBox(height: 12),

            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),

            const SizedBox(height: 24,),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("0.12", style: TextStyle(color: Colors.white70)),
                Text("1.12", style: TextStyle(color: Colors.white70),)
              ],
            )
        ],
        
      ),
    );
  }
}
