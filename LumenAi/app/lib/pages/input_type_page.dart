import 'package:app/pages/recorder.dart';
import 'package:flutter/material.dart';
// import '../models/add_notes.dart';
// import 'results_page.dart';
import 'file_input_page.dart';

class InputTypePage extends StatelessWidget {
  final String className;
  // final AddNotes addNotes;

  const InputTypePage({super.key, required this.className});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(className)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //  Text("Choose input type"),
          _InputTypeButton(
            icon: Icons.mic,
            label: "Record Audio",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FlashCardPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _InputTypeButton(
            icon: Icons.upload_file,
            label: "Upload File",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FileInputPage(className: className),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InputTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _InputTypeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
