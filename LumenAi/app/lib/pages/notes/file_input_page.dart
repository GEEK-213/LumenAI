import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/data_models.dart';
import '../../services/api_service.dart';
import 'results_page.dart';

class FileInputPage extends StatefulWidget {
  final String className;
  final bool isSyllabus;

  const FileInputPage({
    super.key,
    required this.className,
    this.isSyllabus = false,
  });

  @override
  State<FileInputPage> createState() => _FileInputPageState();
}

class _FileInputPageState extends State<FileInputPage> {
  final ApiService _apiService = ApiService();
  final SupabaseClient _supabase = Supabase.instance.client;

  File? selectedFile;
  bool isProcessing = false;
  double _uploadProgress = 0.0;
  String _uploadStage = '';

  // Dropdown State
  List<Subject> _subjects = [];
  List<Unit> _units = [];
  Subject? _selectedSubject;
  Unit? _selectedUnit;
  bool _isLoadingContext = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final subjects = await _apiService.getSubjects();
      setState(() {
        _subjects = subjects;
        _isLoadingContext = false;
      });
    } catch (e) {
      print("Error loading subjects: $e");
      setState(() => _isLoadingContext = false);
    }
  }

  Future<void> _loadUnits(String subjectId) async {
    final units = await _apiService.getUnits(subjectId);
    setState(() {
      _units = units;
      _selectedUnit = null;
    });
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        // Documents
        'pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx',
        // Text
        'txt', 'md', 'rtf', 'csv',
        // Audio
        'mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac', 'opus', 'wma',
        // Video
        'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp',
      ],
    );

    if (result == null) return;

    setState(() {
      selectedFile = File(result.files.single.path!);
    });
  }

  Future<void> _analyzeFile() async {
    if (selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a file.")));
      return;
    }

    setState(() => isProcessing = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You must be logged in to process a lecture."),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => isProcessing = false);
        return;
      }
      final userId = user.id;

      if (widget.isSyllabus) {
        if (_selectedSubject == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please select a Subject for the syllabus."),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => isProcessing = false);
          return;
        }

        final fileName = selectedFile!.path.split('/').last;

        setState(() {
          _uploadProgress = 0.0;
          _uploadStage = 'Uploading Syllabus...';
        });

        await _apiService.uploadSyllabus(
          documentFile: selectedFile!,
          subjectId: _selectedSubject!.id,
          unitId: _selectedUnit?.id,
          userId: userId,
          title: fileName,
          onProgress: (sent, total) {
            setState(() {
              _uploadProgress = sent / total;
              if (_uploadProgress >= 1.0) {
                _uploadStage = "Processing Data...";
              }
            });
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Syllabus uploaded successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final fileName = selectedFile!.path.split('/').last;

        if (_selectedSubject == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please select a Subject for this lecture."),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => isProcessing = false);
          return;
        }

        setState(() {
          _uploadProgress = 0.0;
          _uploadStage = 'Uploading Lecture...';
        });

        final result = await _apiService.processLecture(
          audioFile: selectedFile!,
          subjectId: _selectedSubject!.id,
          unitId: _selectedUnit?.id,
          userId: userId,
          title: fileName,
          onProgress: (sent, total) {
            setState(() {
              _uploadProgress = sent / total;
              if (_uploadProgress >= 1.0) {
                _uploadStage = "Analyzing with AI. This may take a minute...";
              }
            });
          },
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AnalysisResultScreen(result: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: Text(
          widget.isSyllabus
              ? "Upload Syllabus • ${widget.className}"
              : "Upload Lecture • ${widget.className}",
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- 1. Context Selector ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2746),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "📚 Context (Syllabus Grounding)",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _isLoadingContext
                      ? const LinearProgressIndicator()
                      : DropdownButtonFormField<Subject>(
                          decoration: const InputDecoration(
                            labelText: "Subject",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                          ),
                          dropdownColor: const Color(0xFF1E2746),
                          style: const TextStyle(color: Colors.white),
                          value: _selectedSubject,
                          items: _subjects.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(s.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSubject = val);
                              _loadUnits(val.id);
                            }
                          },
                        ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Unit>(
                    decoration: const InputDecoration(
                      labelText: "Unit / Module",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    dropdownColor: const Color(0xFF1E2746),
                    style: const TextStyle(color: Colors.white),
                    value: _selectedUnit,
                    items: _units.map((u) {
                      return DropdownMenuItem(value: u, child: Text(u.name));
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedUnit = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 2. File Picker ---
            GestureDetector(
              onTap: pickFile,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    style: BorderStyle.none,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selectedFile != null
                          ? Icons.check_circle
                          : Icons.cloud_upload_outlined,
                      size: 48,
                      color: selectedFile != null ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      selectedFile != null
                          ? selectedFile!.path.split('/').last
                          : "Tap to select audio/video file",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // --- 3. Analyze Button ---
            if (isProcessing)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _uploadProgress < 1.0 ? _uploadProgress : null,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _uploadProgress < 1.0
                        ? "$_uploadStage ${(_uploadProgress * 100).toStringAsFixed(0)}%"
                        : _uploadStage,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _analyzeFile,
                  child: Text(
                    widget.isSyllabus ? "Upload Syllabus" : "Analyze Lecture",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
