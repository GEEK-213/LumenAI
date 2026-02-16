/*
  //  SUPABASE UPLOAD LOGIC ---
  Future<void> _uploadToSupabase() async {
    if (_recordedFilePath == null) return;

    setState(() => _isUploading = true);

    try {
      final file = File(_recordedFilePath!);
      final fileExt = _recordedFilePath!.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'flashcard_audios/$fileName'; // Folder structure in Bucket

      // A. Upload file to Storage Bucket named 'audio_bucket'
      await _supabase.storage.from('audio_bucket').upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // B. Get the Public URL (so we can listen to it later)
      final publicUrl = _supabase.storage.from('audio_bucket').getPublicUrl(filePath);
      
      setState(() {
        _remoteAudioUrl = publicUrl; // Switch to using the remote URL
        _isUploading = false;
      });

      _showSnackBar("Audio saved to cloud successfully!");
      print("File uploaded to: $publicUrl");

    } catch (e) {
      setState(() => _isUploading = false);
      _showSnackBar("Upload failed: $e", isError: true);
    }
  }
  */
// import 'package:app/components/audio_player.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/flashcard.dart';
import '../../components/card.dart';
import '../../components/audio_player_ui.dart';
import '../../components/progress.dart';
import '../../services/audio_service.dart';
import '../../services/audio_player_service.dart';

class FlashCardPage extends StatefulWidget {
  const FlashCardPage({super.key});

  @override
  State<FlashCardPage> createState() => _FlashCardPageState();
}

class _FlashCardPageState extends State<FlashCardPage> {
  int currentIndex = 0;
  bool isFront = true;
  int swipeDirection = 1;

  int? recordingCardIndex;

  bool isRecording = false;
  bool isPlayingAudio = false;

  Offset cardOffset = Offset.zero;

  final AudioService _audioService = AudioService();
  final AudioPlayerService _playerService = AudioPlayerService();

  Timer? _timer;
  int _seconds = 0;
  String recordTime = "00:00";

  final List<MainCard> cards = [
    MainCard(term: "Mitochondria", definition: "Powerhouse of the cell"),
    MainCard(term: "Nucleus", definition: "Controls cell activities"),
  ];

  @override
  void initState() {
    super.initState();
    _audioService.init();
    _playerService.init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioService.dispose();
    _playerService.dispose();
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

  void _resetRecording(MainCard card) {
    _timer?.cancel();
    setState(() {
      _seconds = 0;
      recordTime = "00:00";
      isRecording = false;
      // card.audioPath = null;
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Widget _flipTransition(Widget child, Animation<double> animation) {
    final rotate = Tween<double>(begin: 3.1416, end: 0).animate(animation);

    return AnimatedBuilder(
      animation: rotate,
      child: child,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(rotate.value),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCard = cards[currentIndex];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              ProgressBar(current: currentIndex, total: cards.length),

              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,

                  onTap: () {
                    if (isPlayingAudio) return;
                    setState(() => isFront = !isFront);
                  },

                  onHorizontalDragEnd: (details) {
                    if (isRecording || isPlayingAudio) return;

                    final v = details.primaryVelocity ?? 0;
                    if (v.abs() < 300) return;

                    if (v < 0 && currentIndex < cards.length - 1) {
                      setState(() => cardOffset = const Offset(-1, 0));

                      Future.delayed(const Duration(milliseconds: 220), () {
                        setState(() {
                          
                          _resetRecording(currentCard);
                          currentIndex++;
                          isFront = true;
                          cardOffset = Offset.zero;
                        });
                      });
                    }

                    if (v > 0 && currentIndex > 0) {
                      setState(() => cardOffset = const Offset(1, 0));

                      Future.delayed(const Duration(milliseconds: 220), () {
                        setState(() {
                          _resetRecording(currentCard);
                          currentIndex--;
                          isFront = true;
                          cardOffset = Offset.zero;
                        });
                      });
                    }

                    HapticFeedback.selectionClick();
                  },

                  child: AnimatedSlide(
                    offset: cardOffset,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: _flipTransition,
                      child: Flashcard(
                        key: ValueKey(isFront),
                        text: isFront
                            ? currentCard.term
                            : currentCard.definition,
                        isFront: isFront,
                        hasAudio: currentCard.audioPath != null,
                        isPlaying: isPlayingAudio,
                        onPlay: () async {
                          final path = currentCard.audioPath;
                          if (path == null) return;

                          setState(() => isPlayingAudio = true);
                          await _playerService.play(path);
                          setState(() => isPlayingAudio = false);
                        },
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: AudioRecorderUI(
                  isRecording: isRecording,
                  time: recordTime,
                  hasAudio: currentCard.audioPath != null,
                  onRecordTap: () async {
                    if (!_audioService.isRunning) {
                      await _audioService.start();

                      _startTimer();

                      setState(() {
                        isRecording = true;
                        recordingCardIndex = currentIndex;
                      });
                      await _audioService.start();
                    } else {
                      final path = await _audioService.stop();

                      _stopTimer();

                      setState(() {
                        isRecording = false;
                        if (recordingCardIndex != null) {
                          cards[recordingCardIndex!].audioPath = path;
                        }

                        recordingCardIndex = null;
                      });
                    }
                  },
                  onReset: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Reset recording?"),
                        content: const Text(
                          "This will delete the recorded audio for this card.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              _resetRecording(currentCard);
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Reset",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
