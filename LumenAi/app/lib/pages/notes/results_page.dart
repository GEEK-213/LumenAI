import 'package:flutter/material.dart';
import '../../models/data_models.dart';

class AnalysisResultScreen extends StatefulWidget {
  final AnalysisResult result;

  const AnalysisResultScreen({super.key, required this.result});

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildQuizTab(),
          _buildFlashcardsTab(),
          _buildMindMapTab(), // Placeholder for now
        ],
      ),
    );
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
              widget.result.summary,
              style: const TextStyle(color: Colors.white, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle("Key Topics"),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: widget.result.topics
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
          if (widget.result.tasks.isNotEmpty) ...[
            _buildSectionTitle("Tasks & Deadlines"),
            const SizedBox(height: 10),
            ...widget.result.tasks.map(
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
    if (widget.result.quizQuestions.isEmpty) {
      return const Center(
        child: Text(
          "No quiz questions generated.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.result.quizQuestions.length,
      itemBuilder: (ctx, i) {
        final q = widget.result.quizQuestions[i];
        return Card(
          color: const Color(0xFF1E2746),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Q${i + 1}: ${q.question}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...q.options.map(
                  (opt) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: opt == q.correctAnswer
                            ? Colors.green
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            opt,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        if (opt == q.correctAnswer)
                          const Icon(
                            Icons.check,
                            color: Colors.green,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Explanation: ${q.explanation}",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 3. Flashcards Tab ---
  Widget _buildFlashcardsTab() {
    if (widget.result.flashcards.isEmpty) {
      return const Center(
        child: Text(
          "No flashcards generated.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.result.flashcards.length,
      itemBuilder: (ctx, i) {
        final f = widget.result.flashcards[i];
        return Card(
          color: const Color(0xFF1E2746),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              f.front,
              style: const TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(f.back, style: const TextStyle(color: Colors.white)),
            ),
          ),
        );
      },
    );
  }

  // --- 4. Mind Map Tab (Placeholder) ---
  Widget _buildMindMapTab() {
    // Implementing a full graph view is complex.
    // For now, we'll list the nodes close to the edges to show the relationships textually.
    if (widget.result.mindMap == null || widget.result.mindMap!.nodes.isEmpty) {
      return const Center(
        child: Text("No mind map data.", style: TextStyle(color: Colors.white)),
      );
    }

    final nodes = widget.result.mindMap!.nodes;
    final edges = widget.result.mindMap!.edges;

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
