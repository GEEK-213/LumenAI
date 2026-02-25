import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/data_models.dart';

import '../../services/api_service.dart';

class AnalysisResultScreen extends StatefulWidget {
  final AnalysisResult result;
  final String? lectureId; // Pass lecture ID so we can refetch easily

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
    _tabController = TabController(length: 4, vsync: this);
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
          tabs: const [
            Tab(text: "Summary"),
            Tab(text: "Quiz"),
            Tab(text: "Cards"),
            Tab(text: "Mind Map"),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSummaryTab(),
            _buildQuizTab(),
            _buildFlashcardsTab(),
            _buildMindMapTab(),
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
      // In a real implementation, you would call `_apiService.getLecture(widget.lectureId)`
      // For this refactor, we simulate the structure.
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
            child: Text(
              _currentResult.summary,
              style: const TextStyle(color: Colors.white, height: 1.5),
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

  // --- 2. Quiz Tab ---
  Widget _buildQuizTab() {
    if (_currentResult.quizQuestions.isEmpty) {
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _currentResult.quizQuestions.length,
      itemBuilder: (ctx, i) {
        final q = _currentResult.quizQuestions[i];
        return InteractiveQuizCard(questionIndex: i + 1, question: q);
      },
    );
  }

  // --- 3. Flashcards Tab ---
  Widget _buildFlashcardsTab() {
    if (_currentResult.flashcards.isEmpty) {
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
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 1.5,
        mainAxisSpacing: 16,
      ),
      itemCount: _currentResult.flashcards.length,
      itemBuilder: (ctx, i) {
        final f = _currentResult.flashcards[i];
        return InteractiveFlashcard(front: f.front, back: f.back);
      },
    );
  }

  // --- 4. Mind Map Tab ---
  Widget _buildMindMapTab() {
    // Implementing a full graph view is complex.
    // For now, we'll list the nodes close to the edges to show the relationships textually.
    if (_currentResult.mindMap == null ||
        _currentResult.mindMap!.nodes.isEmpty) {
      return const Center(
        child: Text("No mind map data.", style: TextStyle(color: Colors.white)),
      );
    }

    final nodes = _currentResult.mindMap!.nodes;
    final edges = _currentResult.mindMap!.edges;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mind Map Connections",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...edges.map((e) {
            final fromNode = nodes.firstWhere(
              (n) => n['id'] == e['from'],
              orElse: () => {'label': '?'},
            )['label'];
            final toNode = nodes.firstWhere(
              (n) => n['id'] == e['to'],
              orElse: () => {'label': '?'},
            )['label'];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2746),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(fromNode, style: const TextStyle(color: Colors.white)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.arrow_forward, color: Colors.blueAccent),
                  ),
                  Text(toNode, style: const TextStyle(color: Colors.white)),
                ],
              ),
            );
          }),
        ],
      ),
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

// --- Interactive Widgets ---

class InteractiveQuizCard extends StatefulWidget {
  final int questionIndex;
  final QuizQuestion question;

  const InteractiveQuizCard({
    super.key,
    required this.questionIndex,
    required this.question,
  });

  @override
  State<InteractiveQuizCard> createState() => _InteractiveQuizCardState();
}

class _InteractiveQuizCardState extends State<InteractiveQuizCard> {
  String? selectedOption;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
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
              "Q${widget.questionIndex}: ${q.question}",
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
                // Before revealing (fallback if needed)
                borderColor = Colors.blueAccent;
                highlightColor = Colors.blueAccent.withOpacity(0.2);
              }

              return GestureDetector(
                onTap: () {
                  if (!isAnswered) {
                    setState(() => selectedOption = opt);
                  }
                },
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

class InteractiveFlashcard extends StatefulWidget {
  final String front;
  final String back;

  const InteractiveFlashcard({
    super.key,
    required this.front,
    required this.back,
  });

  @override
  State<InteractiveFlashcard> createState() => _InteractiveFlashcardState();
}

class _InteractiveFlashcardState extends State<InteractiveFlashcard> {
  bool isFlipped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => isFlipped = !isFlipped);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final rotateAnim = Tween(begin: 3.14, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotateAnim,
            child: child,
            builder: (context, widgetChild) {
              final isUnder = (ValueKey(isFlipped) != widgetChild?.key);
              var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
              tilt *= isUnder ? -1.0 : 1.0;
              final value = isUnder
                  ? min(rotateAnim.value, 1.57)
                  : rotateAnim.value;
              return Transform(
                transform: Matrix4.rotationX(value)..setEntry(3, 1, tilt),
                alignment: Alignment.center,
                child: widgetChild,
              );
            },
          );
        },
        child: isFlipped
            ? _buildCardSide(widget.back, true, key: const ValueKey(true))
            : _buildCardSide(widget.front, false, key: const ValueKey(false)),
      ),
    );
  }

  Widget _buildCardSide(String text, bool isBack, {required Key key}) {
    return Container(
      key: key,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isBack ? const Color(0xFF2C3E50) : const Color(0xFF1E2746),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBack ? Colors.blueAccent : Colors.white12,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isBack ? Colors.white : Colors.blueAccent,
                fontSize: 18,
                fontWeight: isBack ? FontWeight.w500 : FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Icon(Icons.touch_app, color: Colors.white24, size: 24),
          ),
        ],
      ),
    );
  }
}
