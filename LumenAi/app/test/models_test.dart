import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/data_models.dart';
import 'package:app/models/profile.dart';

/// Comprehensive model tests — verify JSON parsing, edge cases, null safety.
void main() {
  // ═══════════════════════════════════════════════════════════
  // 1. AnalysisResult Tests
  // ═══════════════════════════════════════════════════════════

  group('AnalysisResult', () {
    test('parses a full JSON response correctly', () {
      final json = {
        'summary': 'Test lecture about neural networks.',
        'topics': ['ML', 'DL', 'CNNs'],
        'flashcards': [
          {'front': 'Term 1', 'back': 'Definition 1'},
          {'front': 'Term 2', 'back': 'Definition 2'},
        ],
        'quiz_questions': [
          {
            'question': 'What is ML?',
            'options': ['A', 'B', 'C', 'D'],
            'correct_answer': 'A',
            'explanation': 'ML is Machine Learning.',
          },
        ],
        'mind_map': {
          'nodes': [
            {'id': '1', 'label': 'AI'},
            {'id': '2', 'label': 'ML'},
          ],
          'edges': [
            {'from': '1', 'to': '2'},
          ],
        },
        'code_snippets': [
          {
            'title': 'Hello',
            'language': 'python',
            'code_content': 'print("hi")',
          },
        ],
        'extracted_tasks': [
          {'title': 'HW 1', 'due_date': '2026-03-15'},
        ],
        'teacher_questions': ['Explain backprop'],
        'transcript': 'Full text here.',
      };

      final result = AnalysisResult.fromJson(json);

      expect(result.summary, 'Test lecture about neural networks.');
      expect(result.topics, hasLength(3));
      expect(result.flashcards, hasLength(2));
      expect(result.flashcards[0].front, 'Term 1');
      expect(result.quizQuestions, hasLength(1));
      expect(result.quizQuestions[0].options, hasLength(4));
      expect(result.mindMap, isNotNull);
      expect(result.mindMap!.nodes, hasLength(2));
      expect(result.mindMap!.edges, hasLength(1));
      expect(result.codeSnippets, hasLength(1));
      expect(result.tasks, hasLength(1));
      expect(result.tasks[0], 'HW 1');
      expect(result.teacherQuestions, hasLength(1));
      expect(result.transcript, 'Full text here.');
    });

    test('handles missing optional fields', () {
      final json = {'summary': 'Summary only.', 'transcript': 'Trans.'};

      final result = AnalysisResult.fromJson(json);

      expect(result.summary, 'Summary only.');
      expect(result.topics, isEmpty);
      expect(result.flashcards, isEmpty);
      expect(result.quizQuestions, isEmpty);
      expect(result.mindMap, isNull);
      expect(result.codeSnippets, isEmpty);
      expect(result.tasks, isEmpty);
      expect(result.teacherQuestions, isEmpty);
    });

    test('handles null values in JSON', () {
      final json = {
        'summary': 'Summary.',
        'topics': null,
        'flashcards': null,
        'quiz_questions': null,
        'mind_map': null,
        'code_snippets': null,
        'extracted_tasks': null,
        'teacher_questions': null,
        'transcript': null,
      };

      final result = AnalysisResult.fromJson(json);

      expect(result.topics, isEmpty);
      expect(result.flashcards, isEmpty);
      expect(result.quizQuestions, isEmpty);
      expect(result.mindMap, isNull);
      expect(result.codeSnippets, isEmpty);
      expect(result.tasks, isEmpty);
      expect(result.teacherQuestions, isEmpty);
    });

    test('handles empty JSON', () {
      final json = <String, dynamic>{};
      final result = AnalysisResult.fromJson(json);

      expect(result.summary, isEmpty);
      expect(result.topics, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 2. FlashcardData Tests
  // ═══════════════════════════════════════════════════════════

  group('FlashcardData', () {
    test('parses from JSON map', () {
      final json = {'front': 'Q', 'back': 'A'};
      final card = FlashcardData.fromJson(json);
      expect(card.front, 'Q');
      expect(card.back, 'A');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 3. QuizQuestion Tests
  // ═══════════════════════════════════════════════════════════

  group('QuizQuestion', () {
    test('parses from JSON map', () {
      final json = {
        'question': 'What is 1+1?',
        'options': ['1', '2', '3', '4'],
        'correct_answer': '2',
        'explanation': 'Basic math.',
      };
      final q = QuizQuestion.fromJson(json);
      expect(q.question, 'What is 1+1?');
      expect(q.options, hasLength(4));
      expect(q.correctAnswer, '2');
      expect(q.explanation, 'Basic math.');
    });

    test('handles missing options', () {
      final json = {'question': 'Q', 'correct_answer': 'A'};
      final q = QuizQuestion.fromJson(json);
      expect(q.question, 'Q');
      expect(q.options, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 4. MindMapData Tests
  // ═══════════════════════════════════════════════════════════

  group('MindMapData', () {
    test('parses nodes and edges', () {
      final json = {
        'nodes': [
          {'id': '1', 'label': 'Root'},
          {'id': '2', 'label': 'Child'},
        ],
        'edges': [
          {'from': '1', 'to': '2'},
        ],
      };
      final mm = MindMapData.fromJson(json);
      expect(mm.nodes, hasLength(2));
      expect(mm.edges, hasLength(1));
    });

    test('handles integer node IDs', () {
      final json = {
        'nodes': [
          {'id': 1, 'label': 'Root'},
          {'id': 2, 'label': 'Child'},
        ],
        'edges': [
          {'from': 1, 'to': 2},
        ],
      };
      final mm = MindMapData.fromJson(json);
      expect(mm.nodes, hasLength(2));
    });

    test('handles empty mind map', () {
      final json = {'nodes': [], 'edges': []};
      final mm = MindMapData.fromJson(json);
      expect(mm.nodes, isEmpty);
      expect(mm.edges, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 5. Subject & Unit Tests
  // ═══════════════════════════════════════════════════════════

  group('Subject', () {
    test('parses from JSON', () {
      final json = {'id': 'abc', 'name': 'Math', 'user_id': 'u1'};
      final subject = Subject.fromJson(json);
      expect(subject.id, 'abc');
      expect(subject.name, 'Math');
    });
  });

  group('Unit', () {
    test('parses from JSON', () {
      final json = {
        'id': 'u1',
        'name': 'Unit 1',
        'subject_id': 's1',
        'unit_number': 1,
      };
      final unit = Unit.fromJson(json);
      expect(unit.id, 'u1');
      expect(unit.name, 'Unit 1');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 6. Profile Model Tests
  // ═══════════════════════════════════════════════════════════

  group('Profile', () {
    test('parses from JSON', () {
      final json = {
        'id': 'p1',
        'full_name': 'Faaris',
        'avatar_url': 'https://example.com/avatar.png',
        'role': 'student',
      };
      final profile = Profile.fromJson(json);
      expect(profile.fullName, 'Faaris');
      expect(profile.role, 'student');
    });

    test('handles missing optional fields', () {
      final json = {'id': 'p1'};
      final profile = Profile.fromJson(json);
      expect(profile.fullName, isNull);
      expect(profile.avatarUrl, isNull);
    });

    test('toJson round-trip', () {
      final json = {
        'id': 'p1',
        'full_name': 'Test',
        'avatar_url': null,
        'role': 'teacher',
        'interests': ['math', 'science'],
        'stats': {'lectures': 5},
      };
      final profile = Profile.fromJson(json);
      final output = profile.toJson();
      expect(output['full_name'], 'Test');
      expect(output['role'], 'teacher');
      expect(output['interests'], hasLength(2));
    });
  });
}
