import 'package:flutter/material.dart';

class AudioRecorderUI extends StatelessWidget {
  final bool isRecording;
  final String time;
  final VoidCallback onRecordTap;
  final bool hasAudio;
  final VoidCallback onReset;

  const AudioRecorderUI({
    super.key,
    required this.isRecording,
    required this.time,
    required this.onRecordTap,
    required this.hasAudio,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withOpacity(0.25),
      ),
      child: Column(
        children: [
          // Recording status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isRecording ? Colors.redAccent : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isRecording ? "Recording…" : "Not recording",
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Timer
          Text(
            time,
            style: const TextStyle(
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          // Controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mic button
              GestureDetector(
                onTap: onRecordTap,
                child: Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: isRecording
                        ? Colors.redAccent
                        : Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),

              // Reset button (only when audio exists and not recording)
              if (hasAudio && !isRecording) ...[
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.restart_alt),
                  color: Colors.redAccent.withOpacity(0.85),
                  iconSize: 26,
                  onPressed: onReset,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
