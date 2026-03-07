import 'package:flutter/material.dart';
import '../../models/data_models.dart';
import '../../services/api_service.dart';
import '../../services/quiz_service.dart';
import '../../services/gamification_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'mind_map_tab.dart';
import 'code_sandbox_tab.dart';

class AnalysisResultScreen extends StatefulWidget {
  final AnalysisResult result;
  final String? lectureId;

  const AnalysisResultScreen({super.key, required this.result, this.lectureId});

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnalysisResult _currentResult;
  bool _isRefreshing = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _currentResult = widget.result;
    _tabController = TabController(
      length: _currentResult.codeSnippets.isNotEmpty ? 5 : 4,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Analysis Results",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          isScrollable: _currentResult.codeSnippets.isNotEmpty,
          tabs: [
            const Tab(text: "Summary"),
            const Tab(text: "Quiz"),
            const Tab(text: "Cards"),
            const Tab(text: "Mind Map"),
            if (_currentResult.codeSnippets.isNotEmpty) const Tab(text: "Code"),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSummaryTab(),
            EnhancedQuizTab(
              questions: _currentResult.quizQuestions,
              lectureId: widget.lectureId,
            ),
            EnhancedFlashcardsTab(
              flashcards: _currentResult.flashcards,
              lectureId: widget.lectureId,
            ),
            _buildMindMapTab(),
            if (_currentResult.codeSnippets.isNotEmpty)
              CodeSandboxTab(codeSnippets: _currentResult.codeSnippets),
          ],
        ),
      ),
      floatingActionButton: _isRefreshing
          ? const FloatingActionButton(
              onPressed: null,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : FloatingActionButton(
              onPressed: _refreshData,
              tooltip: 'Refresh Analysis',
              child: const Icon(Icons.refresh),
            ),
    );
  }

  Future<void> _refreshData() async {
    if (widget.lectureId == null) return;
    setState(() => _isRefreshing = true);

    try {
      final updatedResult = await _apiService.getAnalysisResult(
        widget.lectureId!,
      );
      if (updatedResult != null && mounted) {
        setState(() {
          _currentResult = updatedResult;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Analysis refreshed!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to refresh: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  // --- 1. Summary Tab ---
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Summary"),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2746),
              borderRadius: BorderRadius.circular(12),
            ),
            child: MarkdownBody(
              data: _currentResult.summary,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: Colors.white, height: 1.5),
                strong: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                listBullet: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle("Key Topics"),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _currentResult.topics
                .map(
                  (t) => Chip(
                    label: Text(t),
                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          if (_currentResult.tasks.isNotEmpty) ...[
            _buildSectionTitle("Tasks & Deadlines"),
            const SizedBox(height: 10),
            ..._currentResult.tasks.map(
              (task) => ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.greenAccent,
                ),
                title: Text(
                  task,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 4. Mind Map Tab ---
  Widget _buildMindMapTab() {
    if (_currentResult.mindMap == null ||
        _currentResult.mindMap!.nodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_tree, size: 48, color: Colors.white24),
            SizedBox(height: 12),
            Text('No mind map data.', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return MindMapView(
      nodes: _currentResult.mindMap!.nodes,
      edges: _currentResult.mindMap!.edges,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF64B5F6),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ENHANCED QUIZ TAB — Score tracker + Completion modal + Retake
// ═══════════════════════════════════════════════════════════

class EnhancedQuizTab extends StatefulWidget {
  final List<QuizQuestion> questions;
  final String? lectureId;

  const EnhancedQuizTab({super.key, required this.questions, this.lectureId});

  @override
  State<EnhancedQuizTab> createState() => _EnhancedQuizTabState();
}

class _EnhancedQuizTabState extends State<EnhancedQuizTab> {
  final Map<int, String> _selectedAnswers = {};
  final QuizService _quizService = QuizService();
  final ApiService _apiService = ApiService();

  late List<QuizQuestion> _currentQuestions;
  bool _quizCompleted = false;
  bool _isGeneratingNewQuiz = false;

  @override
  void initState() {
    super.initState();
    _currentQuestions = widget.questions;
  }

  int get _correctCount {
    int count = 0;
    for (final entry in _selectedAnswers.entries) {
      if (entry.value == _currentQuestions[entry.key].correctAnswer) {
        count++;
      }
    }
    return count;
  }

  int get _answeredCount => _selectedAnswers.length;
  int get _totalCount => _currentQuestions.length;
  double get _percentage =>
      _totalCount > 0 ? (_correctCount / _totalCount) * 100 : 0;

  Color get _scoreColor {
    if (_percentage >= 80) return Colors.greenAccent;
    if (_percentage >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String get _scoreEmoji {
    if (_percentage >= 90) return "🏆";
    if (_percentage >= 80) return "🌟";
    if (_percentage >= 60) return "👍";
    if (_percentage >= 40) return "📚";
    return "💪";
  }

  void _selectAnswer(int questionIndex, String option) {
    if (_selectedAnswers.containsKey(questionIndex)) return;
    setState(() {
      _selectedAnswers[questionIndex] = option;
    });

    // Check if quiz is complete
    if (_answeredCount == _totalCount && !_quizCompleted) {
      _quizCompleted = true;
      _saveAndShowResults();
    }
  }

  Future<void> _saveAndShowResults() async {
    // Save to DB
    if (widget.lectureId != null) {
      try {
        await _quizService.saveAttempt(
          lectureId: widget.lectureId!,
          score: _correctCount,
          total: _totalCount,
        );

        // Gamification: Award 10 Lumen Coins per correct answer
        if (_correctCount > 0) {
          final gamification = GamificationService();
          await gamification.awardCoins(
            _correctCount * 10,
            reason: "Quiz Completion",
          );
        }
      } catch (e) {
        debugPrint("Error saving quiz attempt or awarding coins: $e");
      }
    }

    // Show completion modal
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showCompletionDialog();
      });
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2746),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "$_scoreEmoji Quiz Complete!",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 22),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$_correctCount / $_totalCount correct",
              style: TextStyle(
                color: _scoreColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${_percentage.toStringAsFixed(0)}%",
              style: TextStyle(color: _scoreColor, fontSize: 20),
            ),
            const SizedBox(height: 16),
            Text(
              _percentage >= 80
                  ? "Excellent! You've mastered this material!"
                  : _percentage >= 50
                  ? "Good effort! Review the explanations below."
                  : "Keep studying! Focus on the topics you missed.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _retakeQuiz();
            },
            child: const Text(
              "Retake",
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text("Review Answers"),
          ),
        ],
      ),
    );
  }

  Future<void> _retakeQuiz() async {
    if (widget.lectureId == null) {
      // Offline or no ID, just reset
      setState(() {
        _selectedAnswers.clear();
        _quizCompleted = false;
      });
      return;
    }

    setState(() {
      _isGeneratingNewQuiz = true;
      _selectedAnswers.clear();
      _quizCompleted = false;
    });

    try {
      final newQuestions = await _apiService.generateDynamicQuiz(
        widget.lectureId!,
      );
      if (mounted) {
        setState(() {
          _currentQuestions = newQuestions;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generated 5 novel questions!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate new quiz: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingNewQuiz = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGeneratingNewQuiz) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.orangeAccent),
            const SizedBox(height: 20),
            const Text(
              "Generating novel questions...",
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_currentQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              "Generating quiz questions in the background...",
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Tap the Refresh (↻) button in a few seconds.",
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Score tracker bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              // Progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$_answeredCount / $_totalCount answered",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _totalCount > 0
                            ? _answeredCount / _totalCount
                            : 0,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _answeredCount == _totalCount
                              ? _scoreColor
                              : Colors.blueAccent,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Score
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _scoreColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _scoreColor.withOpacity(0.4)),
                ),
                child: Text(
                  "✓ $_correctCount",
                  style: TextStyle(
                    color: _scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              // Retake button (only after completion)
              if (_quizCompleted) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.replay, color: Colors.orangeAccent),
                  tooltip: 'Retake Quiz',
                  onPressed: _retakeQuiz,
                ),
              ],
            ],
          ),
        ),
        // Quiz cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _currentQuestions.length,
            itemBuilder: (ctx, i) {
              final q = _currentQuestions[i];
              return _buildQuizCard(i, q);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuizCard(int index, QuizQuestion q) {
    final selectedOption = _selectedAnswers[index];
    final isAnswered = selectedOption != null;

    return Card(
      color: const Color(0xFF1E2746),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Q${index + 1}: ${q.question}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...q.options.map((opt) {
              final isSelected = selectedOption == opt;
              final isCorrectResult = isAnswered && opt == q.correctAnswer;
              final isWrongSelection =
                  isAnswered && isSelected && opt != q.correctAnswer;

              Color borderColor = Colors.black12;
              Color highlightColor = Colors.transparent;

              if (isCorrectResult) {
                borderColor = Colors.green;
                highlightColor = Colors.green.withOpacity(0.2);
              } else if (isWrongSelection) {
                borderColor = Colors.red;
                highlightColor = Colors.red.withOpacity(0.2);
              } else if (isSelected) {
                borderColor = Colors.blueAccent;
                highlightColor = Colors.blueAccent.withOpacity(0.2);
              }

              return GestureDetector(
                onTap: () => _selectAnswer(index, opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: highlightColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          opt,
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isCorrectResult)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                      if (isWrongSelection)
                        const Icon(Icons.cancel, color: Colors.red, size: 20),
                    ],
                  ),
                ),
              );
            }),
            if (isAnswered) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueGrey.withOpacity(0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Explanation: ${q.explanation}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ENHANCED FLASHCARDS TAB — Swipeable PageView + Progress
// ═══════════════════════════════════════════════════════════

class EnhancedFlashcardsTab extends StatefulWidget {
  final List<FlashcardData> flashcards;
  final String? lectureId;

  const EnhancedFlashcardsTab({
    super.key,
    required this.flashcards,
    this.lectureId,
  });

  @override
  State<EnhancedFlashcardsTab> createState() => _EnhancedFlashcardsTabState();
}

class _EnhancedFlashcardsTabState extends State<EnhancedFlashcardsTab> {
  final ApiService _apiService = ApiService();
  late PageController _pageController;
  late List<FlashcardData> _currentFlashcards;
  int _currentIndex = 0;
  final Map<int, bool> _confidence = {}; // true = know, false = review
  bool _showSummary = false;
  bool _isGeneratingNew = false;

  int get _knownCount => _confidence.values.where((v) => v).length;
  int get _reviewCount => _confidence.values.where((v) => !v).length;

  @override
  void initState() {
    super.initState();
    _currentFlashcards = widget.flashcards;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _markCard(bool knows) {
    setState(() {
      _confidence[_currentIndex] = knows;
    });

    // Auto-advance to next card
    if (_currentIndex < _currentFlashcards.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Last card — show summary
      setState(() => _showSummary = true);
    }
  }

  void _restart() {
    setState(() {
      _confidence.clear();
      _currentIndex = 0;
      _showSummary = false;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _generateMoreCards() async {
    if (widget.lectureId == null) return;

    setState(() {
      _isGeneratingNew = true;
      _showSummary = false;
    });

    try {
      final newCards = await _apiService.generateDynamicFlashcards(
        widget.lectureId!,
      );
      if (mounted) {
        setState(() {
          _currentFlashcards = newCards;
          _confidence.clear();
          _currentIndex = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generated 5 novel flashcards!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate cards: $e')));
        setState(() => _showSummary = true); // Rollback to summary
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingNew = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGeneratingNew) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text(
              "Generating novel flashcards...",
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_currentFlashcards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              "Generating flashcards in the background...",
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Tap the Refresh (↻) button in a few seconds.",
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_showSummary) return _buildMasterySummary();

    return Column(
      children: [
        // Progress bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Card ${_currentIndex + 1} of ${_currentFlashcards.length}",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.greenAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$_knownCount",
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.replay, color: Colors.orangeAccent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "$_reviewCount",
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _currentFlashcards.isNotEmpty
                      ? (_currentIndex + 1) / _currentFlashcards.length
                      : 0,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.blueAccent,
                  ),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
        // Flashcard PageView
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _currentFlashcards.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (ctx, i) {
              final card = _currentFlashcards[i];
              return _SwipeableFlashcard(
                front: card.front,
                back: card.back,
                onKnow: () => _markCard(true),
                onReview: () => _markCard(false),
                confidence: _confidence[i],
              );
            },
          ),
        ),
        // Swipe hint
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back,
                color: Colors.redAccent.withOpacity(0.5),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "Swipe or use buttons below",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                color: Colors.greenAccent.withOpacity(0.5),
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMasterySummary() {
    final total = _currentFlashcards.length;
    final mastery = total > 0 ? (_knownCount / total * 100) : 0.0;
    final color = mastery >= 80
        ? Colors.greenAccent
        : mastery >= 50
        ? Colors.orangeAccent
        : Colors.redAccent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mastery >= 80
                  ? "🏆"
                  : mastery >= 50
                  ? "👍"
                  : "📚",
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              "Flashcard Review Complete!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "${mastery.toStringAsFixed(0)}% Mastery",
              style: TextStyle(
                color: color,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$_knownCount known · $_reviewCount need review",
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_reviewCount > 0)
                  OutlinedButton.icon(
                    onPressed: _restart,
                    icon: const Icon(Icons.replay, color: Colors.orangeAccent),
                    label: const Text(
                      "Review Missed",
                      style: TextStyle(color: Colors.orangeAccent),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orangeAccent),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Start Over"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.lectureId != null)
              TextButton.icon(
                onPressed: _generateMoreCards,
                icon: const Icon(
                  Icons.auto_awesome,
                  color: Colors.purpleAccent,
                ),
                label: const Text(
                  "Generate More Cards",
                  style: TextStyle(color: Colors.purpleAccent, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Individual flashcard with flip + swipe confidence buttons
class _SwipeableFlashcard extends StatefulWidget {
  final String front;
  final String back;
  final VoidCallback onKnow;
  final VoidCallback onReview;
  final bool? confidence;

  const _SwipeableFlashcard({
    required this.front,
    required this.back,
    required this.onKnow,
    required this.onReview,
    this.confidence,
  });

  @override
  State<_SwipeableFlashcard> createState() => _SwipeableFlashcardState();
}

class _SwipeableFlashcardState extends State<_SwipeableFlashcard> {
  bool _isFlipped = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Card
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isFlipped = !_isFlipped),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _buildCardFace(
                  text: _isFlipped ? widget.back : widget.front,
                  isBack: _isFlipped,
                  key: ValueKey(_isFlipped),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Confidence buttons
          if (widget.confidence == null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ConfidenceButton(
                  label: "Review Again",
                  icon: Icons.replay,
                  color: Colors.redAccent,
                  onTap: widget.onReview,
                ),
                _ConfidenceButton(
                  label: "Know It!",
                  icon: Icons.check_circle,
                  color: Colors.greenAccent,
                  onTap: widget.onKnow,
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    (widget.confidence!
                            ? Colors.greenAccent
                            : Colors.orangeAccent)
                        .withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.confidence!
                    ? "✓ Marked as known"
                    : "↻ Marked for review",
                style: TextStyle(
                  color: widget.confidence!
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardFace({
    required String text,
    required bool isBack,
    required Key key,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isBack
              ? [const Color(0xFF2C3E50), const Color(0xFF1A2530)]
              : [const Color(0xFF1E2746), const Color(0xFF162040)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBack ? Colors.blueAccent.withOpacity(0.5) : Colors.white12,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isBack ? "ANSWER" : "QUESTION",
            style: TextStyle(
              color: (isBack ? Colors.blueAccent : Colors.white38),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isBack ? Colors.white : Colors.blueAccent,
                  fontSize: 20,
                  fontWeight: isBack ? FontWeight.w500 : FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ),
          ),
          Icon(Icons.touch_app, color: Colors.white24, size: 20),
          const SizedBox(height: 4),
          Text(
            "Tap to flip",
            style: TextStyle(color: Colors.white24, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ConfidenceButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
