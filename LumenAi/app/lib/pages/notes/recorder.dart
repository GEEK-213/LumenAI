import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/data_models.dart'; // Import models
import '../../services/audio_service.dart';
import '../../services/api_service.dart'; // Import API Service
import 'results_page.dart'; // Import Results Page

class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});

  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  // Service Instances
  final AudioService _audioService = AudioService();
  final ApiService _apiService = ApiService();
  final SupabaseClient _supabase = Supabase.instance.client;

  // State Variables
  bool isRecording = false;
  bool isProcessing = false;
  String recordTime = "00:00";
  Timer? _timer;
  int _seconds = 0;
  String? _recordedFilePath;
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
    _audioService.init();
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
      _selectedUnit = null; // Reset unit when subject changes
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 0;
    recordTime = "00:00";
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _seconds++;
        recordTime = _formatTime(_seconds);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> _onRecordPressed() async {
    if (isRecording) {
      // STOP RECORDING
      final path = await _audioService.stop();
      _stopTimer();
      setState(() {
        isRecording = false;
        _recordedFilePath = path;
      });
      _showUploadDialog();
    } else {
      // START RECORDING
      // START RECORDING
      // Unit selection is now optional

      await _audioService.start();
      _startTimer();
      setState(() => isRecording = true);
    }
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Analyze Lecture?"),
        content: const Text("Submit this recording to Lumen AI for analysis?"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _recordedFilePath = null;
                recordTime = "00:00";
              });
              Navigator.pop(context);
            },
            child: const Text("Discard"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processRecording();
            },
            child: const Text("Analyze"),
          ),
        ],
      ),
    );
  }

  Future<void> _processRecording() async {
    if (_recordedFilePath == null) return;

    setState(() {
      isProcessing = true;
      _uploadProgress = 0.0;
      _uploadStage = 'Preparing upload...';
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You must be logged in to process a recording."),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => isProcessing = false);
        return;
      }
      final userId = user.id;

      if (_selectedSubject == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please select a Subject for this recording."),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => isProcessing = false);
        return;
      }

      // Stage 1: Uploading
      setState(() {
        _uploadProgress = 0.15;
        _uploadStage = 'Uploading audio...';
      });

      // Small delay for visual feedback
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _uploadProgress = 0.4;
        _uploadStage = 'Sending to Lumen AI...';
      });

      final result = await _apiService.processLecture(
        audioFile: File(_recordedFilePath!),
        subjectId: _selectedSubject!.id,
        unitId: _selectedUnit?.id,
        userId: userId,
        title: _selectedUnit != null
            ? "Lecture on ${_selectedUnit!.name}"
            : "New Recording",
      );

      // Stage 2: AI Processing
      setState(() {
        _uploadProgress = 0.85;
        _uploadStage = 'Analyzing with Gemini...';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _uploadProgress = 1.0;
        _uploadStage = 'Complete!';
      });
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      // Navigate to Results
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AnalysisResultScreen(result: result)),
      );
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
        title: const Text("New Recording"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Context Selector (The Digital Backpack) ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2746),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
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
                    // Subject Dropdown
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
                            initialValue: _selectedSubject,
                            items: _subjects.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
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
                    // Unit Dropdown
                    DropdownButtonFormField<Unit>(
                      decoration: const InputDecoration(
                        labelText: "Unit / Module",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      dropdownColor: const Color(0xFF1E2746),
                      initialValue: _selectedUnit,
                      items: _units.map((u) {
                        return DropdownMenuItem(
                          value: u,
                          child: Text(
                            u.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedUnit = val);
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // --- 2. Recording Status ---
              if (isProcessing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _uploadProgress >= 1.0
                                ? Colors.greenAccent
                                : Theme.of(context).primaryColor,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _uploadStage,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: _uploadProgress >= 1.0
                              ? Colors.greenAccent
                              : Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_uploadProgress < 1.0)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              isProcessing = false;
                              _uploadProgress = 0.0;
                              _uploadStage = '';
                            });
                          },
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.orangeAccent,
                            size: 18,
                          ),
                          label: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.orangeAccent),
                          ),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  recordTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.w200,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),

              const Spacer(),

              // --- 3. Record Button ---
              Center(
                child: GestureDetector(
                  onTap: _onRecordPressed,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isRecording ? 80 : 70,
                    width: isRecording ? 80 : 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRecording ? Colors.red : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: isRecording
                              ? Colors.red.withOpacity(0.5)
                              : Theme.of(context).primaryColor.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      isRecording ? Icons.stop : Icons.mic,
                      color: isRecording ? Colors.white : Colors.black,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
