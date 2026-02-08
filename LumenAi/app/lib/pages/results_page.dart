import 'package:flutter/material.dart';

class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({super.key});

  // Sample Data (Simulating your JSON)
  static final Map<String, dynamic> data = {
    "summary":
        "The audio describes a deeply personal journey of grief and loss following an unexplained event where 'they' are gone. The speaker experiences profound pain, confusion, and loneliness, with time feeling distorted. A significant turning point is the revelation that 'she' was released from a psychiatric ward 426 days later, causing further bewilderment. The narrative culminates in the speaker arriving at a house, hearing laughter, and being confronted by 'she,' who expresses love, despite the speaker's emotional agony, leading to a final, painful goodbye. The story hints at a complex relationship possibly involving mental health issues and a tragic separation.",
    "topics": [
      "Grief and mourning",
      "Loss and separation",
      "Emotional pain and suffering",
      "Loneliness and confusion",
      "Memory and reflection",
      "Mental health (implied)",
      "The passage of time",
      "Unresolved feelings/conflict",
      "Farewell/Ending of a relationship",
    ],
    "tasks": [
      "Identify the primary metaphor used for 'loss'.",
      "List three adjectives the speaker uses to describe the event.",
      "Compare the speaker's tone at the beginning vs. the end.",
    ],
    "teacher_questions": [
      "How does the speaker describe the passage of time?",
      "What evidence suggests the event was unexpected?",
      "Do you think the 'unresolved feelings' are internal or external?",
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Results",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {},
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Summary Section ---
            _buildSectionTitle("Summary"),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2746), // Card Color
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Text(
                data['summary'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.6, // Better readability
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- 2. Topics Section ---
            _buildSectionTitle("Topics"),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10, // Horizontal space between chips
              runSpacing: 10, // Vertical space between lines
              children: (data['topics'] as List<String>).map((topic) {
                return _buildTopicChip(topic);
              }).toList(),
            ),

            const SizedBox(height: 30),

            // --- 3. Tasks Section ---
            _buildSectionTitle("Tasks"),
            const SizedBox(height: 12),
            Column(
              children: (data['tasks'] as List<String>).map((task) {
                return _buildTaskItem(task);
              }).toList(),
            ),

            const SizedBox(height: 30),

            // --- 4. Teacher Questions Section ---
            _buildSectionTitle("Teacher Questions"),
            const SizedBox(height: 12),
            Column(
              children: (data['teacher_questions'] as List<String>).map((
                question,
              ) {
                return _buildQuestionCard(question);
              }).toList(),
            ),

            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }

  //  Widgets

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF64B5F6), // Light Blue Accent
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTopicChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        // Gradient for a modern look matching the dashboard
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E88E5).withOpacity(0.8),
            const Color(0xFF1565C0).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTaskItem(String task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101628), // Slightly darker than card
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF69F0AE),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2746), // Card Color
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: Colors.purpleAccent.shade100,
            width: 4,
          ), // Left colored accent
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.help_outline,
            color: Colors.purpleAccent.shade100,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              question,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}