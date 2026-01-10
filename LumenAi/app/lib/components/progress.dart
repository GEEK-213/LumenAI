import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const ProgressBar({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = (current + 1) / total;

    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${current + 1} / $total",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12
            ),
            ),
            SizedBox(height: 8),

            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            )
          ],
      ),
    );
  }
}
