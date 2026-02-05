import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class FileInputPage extends StatefulWidget {
  final String className;

  const FileInputPage({super.key, required this.className});

  @override
  State<FileInputPage> createState() => _FileInputPageState();
}

class _FileInputPageState extends State<FileInputPage> {
  File? selectedFile;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null) return;

    setState(() {
      selectedFile = File(result.files.single.path!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Files • ${widget.className}")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upload_file, size: 64),
            const SizedBox(height: 20),

            ElevatedButton(onPressed: pickFile, child: const Text("Pick File")),

            const SizedBox(height: 20),

            if (selectedFile != null)
              Column(
                children: [
                  const Text(
                    "Selected file:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedFile!.path.split('/').last,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
