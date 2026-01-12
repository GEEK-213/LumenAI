import 'package:flutter/material.dart';

class AudioRecorderUI extends StatelessWidget {
  final bool isRecording;
  final String time;
  final VoidCallback onRecordTap;

  const AudioRecorderUI({
    super.key,
    required this.isRecording,
    required this.time,
    required this.onRecordTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.red.withOpacity(0.15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isRecording ? Colors.red : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isRecording ? "Recording…" : "Not recording",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            time,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          IconButton(
            iconSize: 56,
            icon: Icon(
              isRecording ? Icons.stop_circle : Icons.mic,
              color: Colors.white,
            ),
            onPressed: onRecordTap,
          ),
        ],
      ),
    );
  }
}
