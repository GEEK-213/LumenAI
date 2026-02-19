import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/data_models.dart';

void main() {
  group('AnalysisResult Parsing', () {
    test('Correctly parses full JSON response from backend', () {
      final Map<String, dynamic> jsonResponse = {
        "summary": "This is a summary.",
        "topics": ["Topic A", "Topic B"],
        "flashcards": [
          {"front": "Front 1", "back": "Back 1"},
          {"front": "Front 2", "back": "Back 2"},
        ],
        "quiz_questions": [
          {
            "question": "What is X?",
            "options": ["A", "B", "C", "D"],
            "correct_answer": "A",
            "explanation": "Because A.",
          },
        ],
        "mind_map": {
          "nodes": [
            {"id": 1, "label": "Root"},
            {"id": "2", "label": "Child"},
          ],
          "edges": [
            {"from": 1, "to": "2"},
          ],
        },
        "extracted_tasks": [
          {"title": "Task 1", "due_date": "2024-01-01"},
          {"title": "Task 2", "due_date": null},
        ],
        "teacher_questions": ["Q1?", "Q2?"],
        "transcript": "Full transcript text.",
      };

      final result = AnalysisResult.fromJson(jsonResponse);

      expect(result.summary, "This is a summary.");
      expect(result.topics.length, 2);
      expect(result.topics.first, "Topic A");
      expect(result.flashcards.length, 2);
      expect(result.flashcards[0].front, "Front 1");
      expect(result.quizQuestions.length, 1);
      expect(result.quizQuestions[0].options.length, 4);
      expect(result.mindMap, isNotNull);
      expect(result.mindMap!.nodes.length, 2);
      expect(result.tasks.length, 2);
      expect(result.tasks[0], "Task 1");
      expect(result.teacherQuestions.length, 2);
      expect(result.transcript, "Full transcript text.");
    });

    test('Handles missing optional fields gracefully', () {
      final Map<String, dynamic> jsonResponse = {
        "summary": "Summary only.",
        "extracted_tasks": [],
        "transcript": "Trans.",
      };

      final result = AnalysisResult.fromJson(jsonResponse);

      expect(result.summary, "Summary only.");
      expect(result.topics, isEmpty);
      expect(result.flashcards, isEmpty);
      expect(result.quizQuestions, isEmpty);
      expect(result.mindMap, isNull);
      expect(result.tasks, isEmpty);
      expect(result.teacherQuestions, isEmpty);
    });

    test('Handles nulls in JSON', () {
      final Map<String, dynamic> jsonResponse = {
        "summary": "Summary.",
        "topics": null,
        "flashcards": null,
        "quiz_questions": null,
        "mind_map": null,
        "extracted_tasks": null,
        "teacher_questions": null,
        "transcript": "Trans.",
      };

      final result = AnalysisResult.fromJson(jsonResponse);

      expect(result.topics, isEmpty);
      expect(result.flashcards, isEmpty);
      expect(result.quizQuestions, isEmpty);
      expect(result.mindMap, isNull);
      expect(result.tasks, isEmpty);
      expect(result.teacherQuestions, isEmpty);
    });
  });
}
