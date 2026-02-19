import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/pages/notes/results_page.dart'; // Adjust path if needed based on package structure
import 'package:app/models/data_models.dart';

void main() {
  // Create a mock AnalysisResult object
  final mockResult = AnalysisResult(
    summary: "This is a Mock Summary for testing.",
    topics: ["Topic A", "Topic B"],
    flashcards: [
      FlashcardData(front: "Front 1", back: "Back 1"),
      FlashcardData(front: "Front 2", back: "Back 2"),
    ],
    quizQuestions: [
      QuizQuestion(
        question: "What is the Mock Question?",
        options: ["Option A", "Option B", "Option C", "Option D"],
        correctAnswer: "Option A",
        explanation: "Explanation for A",
      ),
    ],
    mindMap: MindMapData(
      nodes: [
        {"id": "1", "label": "Root"},
        {"id": "2", "label": "Leaf"},
      ],
      edges: [
        {"from": "1", "to": "2"},
      ],
    ),
    tasks: ["Task 1", "Task 2"],
    teacherQuestions: ["Teacher Q1"],
    transcript: "Full transcript.",
  );

  testWidgets('AnalysisResultScreen displays summary and topics', (
    WidgetTester tester,
  ) async {
    // Build the widget tree
    await tester.pumpWidget(
      MaterialApp(home: AnalysisResultScreen(result: mockResult)),
    );

    // Verify Summary Tab is default and displays content
    expect(find.text("Analysis Results"), findsOneWidget);
    expect(find.text("This is a Mock Summary for testing."), findsOneWidget);
    expect(find.text("Topic A"), findsOneWidget);
    expect(find.text("Task 1"), findsOneWidget);
  });

  testWidgets('AnalysisResultScreen displays quiz tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AnalysisResultScreen(result: mockResult)),
    );

    // Tap on Quiz tab
    await tester.tap(find.text("Quiz"));
    await tester.pumpAndSettle(); // Wait for animation

    // Verify Quiz content
    expect(find.text("Q1: What is the Mock Question?"), findsOneWidget);
    expect(find.text("Option A"), findsOneWidget);
  });

  testWidgets('AnalysisResultScreen displays flashcards tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AnalysisResultScreen(result: mockResult)),
    );

    // Tap on Cards tab
    await tester.tap(find.text("Cards"));
    await tester.pumpAndSettle();

    // Verify Flashcard content
    expect(find.text("Front 1"), findsOneWidget);
    expect(find.text("Back 1"), findsOneWidget);
  });
}
