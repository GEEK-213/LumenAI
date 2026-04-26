import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/data_models.dart';

/// Full-screen Conversational Voice Tutor.
/// Students speak questions → AI answers using RAG → answers are spoken aloud.
class VoiceTutorPage extends StatefulWidget {
  const VoiceTutorPage({super.key});

  @override
  State<VoiceTutorPage> createState() => _VoiceTutorPageState();
}

class _VoiceTutorPageState extends State<VoiceTutorPage>
    with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final ApiService _apiService = ApiService();
  String get _baseUrl => _apiService.baseUrl;

  // State
  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _currentTranscript = '';
  String _lastAnswer = '';
  final List<Map<String, String>> _history = []; // conversation pairs

  // Context selection
  List<Subject> _subjects = [];
  Subject? _selectedSubject;

  // Animations
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _loadSubjects();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) {
        debugPrint('Speech error: $error');
        if (mounted) setState(() => _isListening = false);
      },
      onStatus: (status) {
        debugPrint('Speech status: $status');
        if (status == 'notListening' && mounted) {
          setState(() => _isListening = false);
          // Auto-submit if we have text
          if (_currentTranscript.trim().isNotEmpty && !_isProcessing) {
            _submitQuestion(_currentTranscript);
          }
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _loadSubjects() async {
    try {
      final subjects = await _apiService.getSubjects();
      if (mounted) setState(() => _subjects = subjects);
    } catch (e) {
      debugPrint('Error loading subjects: $e');
    }
  }

  void _startListening() async {
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available on this device.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Stop TTS if speaking
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    }

    setState(() {
      _isListening = true;
      _currentTranscript = '';
    });

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _currentTranscript = result.recognizedWords;
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
      listenMode: stt.ListenMode.dictation,
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);

    if (_currentTranscript.trim().isNotEmpty) {
      _submitQuestion(_currentTranscript);
    }
  }

  Future<void> _submitQuestion(String question) async {
    setState(() {
      _isProcessing = true;
      _lastAnswer = '';
    });

    try {
      // Build conversation context
      final contextParts = _history
          .map((h) => "User: ${h['question']}\nAssistant: ${h['answer']}")
          .join('\n\n');

      final headers = await _apiService.authHeaders;
      headers['Content-Type'] = 'application/x-www-form-urlencoded';

      final body = <String, String>{
        'question': question,
        'context': contextParts,
      };
      if (_selectedSubject != null) {
        body['subject_id'] = _selectedSubject!.id;
      }

      final response = await http
          .post(Uri.parse('$_baseUrl/chat/ask'), headers: headers, body: body)
          .timeout(const Duration(seconds: 45));

      final data = jsonDecode(response.body);
      final answer = data['answer'] ?? 'Sorry, I could not get a response.';

      if (mounted) {
        setState(() {
          _lastAnswer = answer;
          _isProcessing = false;
          _history.add({'question': question, 'answer': answer});
        });

        // Speak the answer
        _speakAnswer(answer);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastAnswer = 'Sorry, I could not connect to the backend.';
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _speakAnswer(String text) async {
    // Clean markdown for TTS
    final cleanText = text
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1') // bold
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1') // italic
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1') // code
        .replaceAll(RegExp(r'#{1,6}\s'), '') // headers
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1') // links
        .replaceAll(RegExp(r'[-*]\s'), '') // bullets
        .trim();

    // Truncate very long responses for TTS (keep first ~500 chars)
    final spokenText = cleanText.length > 600
        ? '${cleanText.substring(0, 600)}... I have more details in the text below.'
        : cleanText;

    setState(() => _isSpeaking = true);
    await _tts.speak(spokenText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B18),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSubjectSelector(),
            Expanded(child: _buildMainContent()),
            _buildConversationHistory(),
            _buildMicArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
          ),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF448AFF), Color(0xFF8E24AA)],
            ).createShader(bounds),
            child: const Text(
              '🎤 Voice Tutor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          if (_history.isNotEmpty)
            IconButton(
              onPressed: () {
                setState(() {
                  _history.clear();
                  _lastAnswer = '';
                  _currentTranscript = '';
                });
              },
              icon: const Icon(Icons.refresh, color: Colors.white38, size: 22),
              tooltip: 'Clear conversation',
            ),
        ],
      ),
    );
  }

  Widget _buildSubjectSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2746),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedSubject?.id,
            hint: const Text(
              'All subjects',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            dropdownColor: const Color(0xFF1E2746),
            isExpanded: true,
            icon: const Icon(Icons.expand_more, color: Colors.white38),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text(
                  'All subjects',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              ..._subjects.map(
                (s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(
                    s.name,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
            onChanged: (val) {
              setState(() {
                _selectedSubject = val == null
                    ? null
                    : _subjects.firstWhere((s) => s.id == val);
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isProcessing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _waveController,
              builder: (_, __) => CustomPaint(
                size: const Size(200, 60),
                painter: _WaveformPainter(
                  _waveController.value,
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Thinking...',
              style: TextStyle(
                color: Theme.of(context).primaryColor.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"$_currentTranscript"',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isSpeaking && _lastAnswer.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _waveController,
              builder: (_, __) => CustomPaint(
                size: const Size(200, 60),
                painter: _WaveformPainter(
                  _waveController.value,
                  Colors.purpleAccent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Speaking...',
              style: TextStyle(color: Colors.purpleAccent, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _lastAnswer,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_lastAnswer.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.purpleAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Lumen AI',
                  style: TextStyle(
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _speakAnswer(_lastAnswer),
                  icon: const Icon(
                    Icons.volume_up,
                    color: Colors.white38,
                    size: 20,
                  ),
                  tooltip: 'Read aloud',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _lastAnswer,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic, size: 64, color: Theme.of(context).primaryColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'Tap the microphone and ask\nanything about your studies',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            'AI answers are grounded in your lecture notes',
            style: TextStyle(
              color: Colors.white.withOpacity(0.15),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationHistory() {
    if (_history.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _history.length,
        itemBuilder: (_, i) {
          final q = _history[i]['question'] ?? '';
          return GestureDetector(
            onTap: () {
              setState(() {
                _lastAnswer = _history[i]['answer'] ?? '';
                _currentTranscript = q;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2746),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Theme.of(context).primaryColor,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    q.length > 25 ? '${q.substring(0, 25)}...' : q,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMicArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF050B18),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          // Live transcript display
          if (_isListening && _currentTranscript.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
              ),
              child: Text(
                _currentTranscript,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ),

          // Mic button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status text
              Expanded(
                child: Text(
                  _isListening
                      ? 'Listening...'
                      : _isProcessing
                      ? 'Processing...'
                      : _isSpeaking
                      ? 'Speaking...'
                      : 'Tap to speak',
                  style: TextStyle(
                    color: _isListening ? Theme.of(context).primaryColor : Colors.white38,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Main mic button
              GestureDetector(
                onTap: _isProcessing
                    ? null
                    : _isListening
                    ? _stopListening
                    : _startListening,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, child) {
                    final scale = _isListening ? _pulseAnimation.value : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isListening
                                ? [Colors.redAccent, Colors.red[800]!]
                                : [
                                    const Color(0xFF448AFF),
                                    const Color(0xFF8E24AA),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isListening
                                          ? Colors.redAccent
                                          : Theme.of(context).primaryColor)
                                      .withOpacity(0.4),
                              blurRadius: _isListening ? 24 : 12,
                              spreadRadius: _isListening ? 4 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Replay button
              Expanded(
                child: _lastAnswer.isNotEmpty && !_isSpeaking
                    ? Center(
                        child: IconButton(
                          onPressed: () => _speakAnswer(_lastAnswer),
                          icon: const Icon(
                            Icons.replay,
                            color: Colors.white38,
                            size: 22,
                          ),
                          tooltip: 'Replay last answer',
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for waveform animation
class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;

  _WaveformPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final barCount = 20;
    final barWidth = size.width / (barCount * 2);

    for (int i = 0; i < barCount; i++) {
      final x = (i * 2 + 1) * barWidth;
      final normalizedPosition = i / barCount;

      // Create a wave pattern that moves over time
      final wave = sin(
        (normalizedPosition * 3.14159 * 2) + (progress * 3.14159 * 4),
      );
      final height = (0.3 + 0.7 * ((wave + 1) / 2)) * size.height * 0.8;

      final y1 = (size.height - height) / 2;
      final y2 = y1 + height;

      paint.color = color.withOpacity(0.3 + 0.5 * ((wave + 1) / 2));
      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
