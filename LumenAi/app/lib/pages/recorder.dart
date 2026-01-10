
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
  import 'package:app/components/audio_player.dart';
import 'package:app/components/bottom_controls.dart';
import 'package:app/components/progress.dart';
import 'package:flutter/material.dart';
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
  bool isPlaying = false;
  double audioProgress = 0.3;

  final List<MainCard> cards = [
    MainCard(term: "microchondria", definition: "powehouse of cell"),
    MainCard(term: "nucleus", definition: "powehouse "),
  ];

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
              //progress bar
              ProgressBar(current: currentIndex, total: cards.length),

              //flashcard
              Expanded(
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        isFront = !isFront;
                        debugPrint("FLIPPED: $isFront");
                        debugPrint(isFront.toString());
                      });
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Flashcard(
                        key: ValueKey(
                          isFront ? currentCard.term : currentCard.definition,
                        ),
                        text: isFront
                            ? currentCard.term
                            : currentCard.definition,
                        isFront: isFront,
                      ),
                    ),
                  ),
                ),
              ),

//audio controls
              AudioPlayerUI(isPlaying: isPlaying, progress: audioProgress, onPlayPause: () {
                setState(() {
                  isPlaying = !isPlaying;
                });
              }),

              //bottom controls
              BottomControls(
                isFirst: currentIndex == 0,
                isLast: currentIndex == cards.length - 1,
                onNext: () {
                  setState(() {
                    currentIndex++;
                    isFront = true;
                  });
                },
                onPrevios: () {
                  setState(() {
                    currentIndex--;
                    isFront = true;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}