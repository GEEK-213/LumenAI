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
import 'package:app/services/audio_player_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/audio_player_ui.dart';
import '../services/audio_service.dart';
import 'dart:async';

import 'package:app/components/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; //newly added- for small sound when card swipes
import '../models/flashcard.dart';
import '../components/card.dart';

class FlashCardPage extends StatefulWidget {
  const FlashCardPage({super.key});

  @override
  State<FlashCardPage> createState() => _FlashCardPageState();
}

class _FlashCardPageState extends State<FlashCardPage> {
  int currentIndex = 0;
  bool isFront = true;
  int swipeDirection = 1;

  bool isRecording = false;
  bool isPlayingAudio = false;

  final AudioService _audioService = AudioService();
  final AudioPlayerService _playerService = AudioPlayerService();

  Timer? _timer;
  int _seconds = 0;
  String recordTime = "00:00";

  final List<MainCard> cards = [
    MainCard(term: "microchondria", definition: "powerhouse of cell"),
    MainCard(term: "nucleus", definition: "controls cell activities"),
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
    _seconds = 0;
    _timer?.cancel();
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

  Widget swipeTransition(Widget child, Animation<double> animation) {
    final tween = Tween<Offset>(
      begin: Offset(swipeDirection.toDouble(), 0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOut));

    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }

  Widget flipTransition(Widget child, Animation<double> animation) {
    final flipAnim = Tween<double>(begin: -1, end: 1).animate(animation);

    return AnimatedBuilder(
      animation: flipAnim,
      child: child,
      builder: (context, child) {
        final scaleX = flipAnim.value.abs();
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(scaleX, 1.0),
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
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              ProgressBar(current: currentIndex, total: cards.length),

              Expanded(
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,

                    onTap: () {
                      if (isPlayingAudio) return;
                      setState(() => isFront = !isFront);
                    },

                    onHorizontalDragEnd: (details) {
                      if (isRecording || isPlayingAudio) return;

                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity.abs() < 300) return;

                      if (velocity < 0 && currentIndex < cards.length - 1) {
                        setState(() {
                          swipeDirection = 1;
                          currentIndex++;
                          isFront = true;
                        });
                      } else if (velocity > 0 && currentIndex > 0) {
                        setState(() {
                          swipeDirection = -1;
                          currentIndex--;
                          isFront = true;
                        });
                      }

                      HapticFeedback.selectionClick();
                    },

                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: swipeTransition,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: flipTransition,
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
              ),

              AudioRecorderUI(
                isRecording: isRecording,
                time: recordTime,
                onRecordTap: () async {
                  if (!_audioService.isRunning) {
                    final path = await _audioService.start();
                    _startTimer();
                    setState(() {
                      isRecording = true;
                      currentCard.audioPath = path;
                    });
                  } else {
                    await _audioService.stop();
                    _stopTimer();
                    setState(() => isRecording = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}