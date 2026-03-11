import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/data_models.dart';
import 'package:app/models/profile.dart';
import 'package:app/pages/notes/mind_map_tab.dart';
import 'package:app/pages/notes/code_sandbox_tab.dart';

// ╔═══════════════════════════════════════════════════════════╗
// ║  LumenAI — Comprehensive Flutter Test Suite              ║
// ║  Run: flutter test test/test_comprehensive.dart          ║
// ╚═══════════════════════════════════════════════════════════╝

void main() {
  // ═════════════ 1. Subject Model ═════════════
  group('Subject Model', () {
    test('fromJson parses correctly', () {
      final s = Subject.fromJson({'id': 'sub1', 'name': 'Physics'});
      expect(s.id, 'sub1');
      expect(s.name, 'Physics');
    });

    test('handles all fields', () {
      final s = Subject.fromJson({'id': 'x', 'name': 'Math'});
      expect(s.id, isNotEmpty);
      expect(s.name, isNotEmpty);
    });
  });

  // ═════════════ 2. Unit Model ═════════════
  group('Unit Model', () {
    test('fromJson parses correctly', () {
      final u = Unit.fromJson({
        'id': 'u1',
        'name': 'Kinematics',
        'subject_id': 'sub1',
      });
      expect(u.id, 'u1');
      expect(u.name, 'Kinematics');
      expect(u.subjectId, 'sub1');
    });
  });

  // ═════════════ 3. AnalysisResult Model ═════════════
  group('AnalysisResult Model', () {
    test('full AI response parsing', () {
      final r = AnalysisResult.fromJson({
        'summary': 'Neural networks explained.',
        'topics': ['ML', 'DL', 'CNNs'],
        'flashcards': [
          {'front': 'Neuron', 'back': 'Processing unit'},
        ],
        'quiz_questions': [
          {
            'question': 'What is ML?',
            'options': ['A', 'B', 'C', 'D'],
            'correct_answer': 'A',
            'explanation': 'x',
          },
        ],
        'mind_map': {
          'nodes': [
            {'id': 1, 'label': 'AI'},
            {'id': 2, 'label': 'ML'},
          ],
          'edges': [
            {'from': 1, 'to': 2},
          ],
        },
        'code_snippets': [
          {
            'title': 'Sort',
            'language': 'python',
            'code_content': 'sorted([3,1])',
          },
        ],
        'extracted_tasks': [
          {'title': 'HW1', 'due_date': '2026-03-15'},
        ],
        'teacher_questions': ['Explain backprop'],
        'transcript': 'Full text here.',
      });

      expect(r.summary, 'Neural networks explained.');
      expect(r.topics.length, 3);
      expect(r.flashcards.length, 1);
      expect(r.quizQuestions.length, 1);
      expect(r.mindMap, isNotNull);
      expect(r.mindMap!.nodes.length, 2);
      expect(r.mindMap!.edges.length, 1);
      expect(r.codeSnippets.length, 1);
      expect(r.tasks.length, 1);
      expect(r.teacherQuestions.length, 1);
      expect(r.transcript, 'Full text here.');
    });

    test('handles completely empty JSON', () {
      final r = AnalysisResult.fromJson({});
      expect(r.summary, '');
      expect(r.topics, isEmpty);
      expect(r.flashcards, isEmpty);
      expect(r.quizQuestions, isEmpty);
      expect(r.mindMap, isNull);
      expect(r.codeSnippets, isEmpty);
      expect(r.tasks, isEmpty);
      expect(r.teacherQuestions, isEmpty);
      expect(r.transcript, '');
    });

    test('handles null mind_map', () {
      final r = AnalysisResult.fromJson({'summary': 'x', 'mind_map': null});
      expect(r.mindMap, isNull);
    });

    test('handles string node IDs in mind_map', () {
      final r = AnalysisResult.fromJson({
        'mind_map': {
          'nodes': [
            {'id': 'n1', 'label': 'Root'},
          ],
          'edges': [
            {'from': 'n1', 'to': 'n2'},
          ],
        },
      });
      expect(r.mindMap!.nodes[0]['id'], 'n1');
    });

    test('handles integer node IDs in mind_map', () {
      final r = AnalysisResult.fromJson({
        'mind_map': {
          'nodes': [
            {'id': 1, 'label': 'Root'},
          ],
          'edges': [],
        },
      });
      expect(r.mindMap!.nodes[0]['id'], 1);
    });

    test('handles multiple code snippets', () {
      final r = AnalysisResult.fromJson({
        'code_snippets': [
          {'title': 'A', 'language': 'python', 'code_content': 'x=1'},
          {'title': 'B', 'language': 'java', 'code_content': 'int x=1;'},
          {'title': 'C', 'language': 'javascript', 'code_content': 'let x=1;'},
        ],
      });
      expect(r.codeSnippets.length, 3);
    });
  });

  // ═════════════ 4. FlashcardData Model ═════════════
  group('FlashcardData Model', () {
    test('parses front and back', () {
      final c = FlashcardData.fromJson({'front': 'Term', 'back': 'Definition'});
      expect(c.front, 'Term');
      expect(c.back, 'Definition');
    });

    test('handles long content', () {
      final long = 'A' * 500;
      final c = FlashcardData.fromJson({'front': long, 'back': long});
      expect(c.front.length, 500);
    });
  });

  // ═════════════ 5. QuizQuestion Model ═════════════
  group('QuizQuestion Model', () {
    test('parses all fields', () {
      final q = QuizQuestion.fromJson({
        'question': 'What?',
        'options': ['A', 'B', 'C', 'D'],
        'correct_answer': 'A',
        'explanation': 'Reason',
      });
      expect(q.question, 'What?');
      expect(q.options.length, 4);
      expect(q.correctAnswer, 'A');
      expect(q.explanation, 'Reason');
    });

    test('defaults explanation to empty', () {
      final q = QuizQuestion.fromJson({
        'question': 'Q?',
        'options': ['A'],
        'correct_answer': 'A',
      });
      expect(q.explanation, '');
    });

    test('handles missing options', () {
      final q = QuizQuestion.fromJson({
        'question': 'Q?',
        'correct_answer': 'A',
      });
      expect(q.options, isEmpty);
    });
  });

  // ═════════════ 6. MindMapData Model ═════════════
  group('MindMapData Model', () {
    test('parses nodes and edges', () {
      final mm = MindMapData.fromJson({
        'nodes': [
          {'id': 1, 'label': 'Root'},
          {'id': 2, 'label': 'Child'},
        ],
        'edges': [
          {'from': 1, 'to': 2},
        ],
      });
      expect(mm.nodes.length, 2);
      expect(mm.edges.length, 1);
    });

    test('handles empty', () {
      final mm = MindMapData.fromJson({});
      expect(mm.nodes, isEmpty);
      expect(mm.edges, isEmpty);
    });

    test('handles empty arrays', () {
      final mm = MindMapData.fromJson({'nodes': [], 'edges': []});
      expect(mm.nodes, isEmpty);
      expect(mm.edges, isEmpty);
    });
  });

  // ═════════════ 7. Profile Model ═════════════
  group('Profile Model', () {
    test('fromJson parses all fields', () {
      final p = Profile.fromJson({
        'id': 'u123',
        'full_name': 'John Doe',
        'avatar_url': 'https://example.com/avatar.jpg',
        'role': 'student',
        'interests': ['AI', 'Music'],
        'stats': {'lectures_analyzed': 5},
      });
      expect(p.id, 'u123');
      expect(p.fullName, 'John Doe');
      expect(p.avatarUrl, 'https://example.com/avatar.jpg');
      expect(p.role, 'student');
      expect(p.interests.length, 2);
      expect(p.stats['lectures_analyzed'], 5);
    });

    test('handles missing optional fields', () {
      final p = Profile.fromJson({'id': 'u1'});
      expect(p.id, 'u1');
      expect(p.fullName, isNull);
      expect(p.avatarUrl, isNull);
      expect(p.role, isNull);
      expect(p.interests, isEmpty);
      expect(p.stats, isEmpty);
    });

    test('toJson round-trip', () {
      final p = Profile(
        id: 'u1',
        fullName: 'Test User',
        role: 'teacher',
        interests: ['Math'],
        stats: {'count': 1},
      );
      final json = p.toJson();
      expect(json['id'], 'u1');
      expect(json['full_name'], 'Test User');
      expect(json['role'], 'teacher');
      expect(json['interests'], ['Math']);

      // Parse back
      final p2 = Profile.fromJson(json);
      expect(p2.id, p.id);
      expect(p2.fullName, p.fullName);
    });

    test('handles empty interests and stats', () {
      final p = Profile.fromJson({'id': 'u1', 'interests': [], 'stats': {}});
      expect(p.interests, isEmpty);
      expect(p.stats, isEmpty);
    });
  });

  // ═════════════ 8. MindMapView Widget ═════════════
  group('MindMapView Widget', () {
    testWidgets('renders empty state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MindMapView(nodes: [], edges: []),
          ),
        ),
      );
      expect(find.text('No mind map data.'), findsOneWidget);
    });

    testWidgets('renders nodes with int IDs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapView(
              nodes: [
                {'id': 1, 'label': 'Root'},
                {'id': 2, 'label': 'Child'},
              ],
              edges: [
                {'from': 1, 'to': 2},
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Root'), findsOneWidget);
      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('renders nodes with string IDs (no crash)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapView(
              nodes: [
                {'id': '1', 'label': 'Root'},
                {'id': '2', 'label': 'Leaf'},
              ],
              edges: [
                {'from': '1', 'to': '2'},
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Root'), findsOneWidget);
    });

    testWidgets('handles single node with no edges', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapView(
              nodes: [
                {'id': 1, 'label': 'Solo'},
              ],
              edges: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Solo'), findsOneWidget);
    });

    testWidgets('truncates long labels (> 20 chars for root)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapView(
              nodes: [
                {'id': 1, 'label': 'Very Long Node Label Here Today'},
              ],
              edges: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Very Long Node Lab..'), findsOneWidget);
    });

    testWidgets('does NOT truncate short labels (within 20 chars for root)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapView(
              nodes: [
                {'id': 1, 'label': 'ShortLabel'},
              ],
              edges: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ShortLabel'), findsOneWidget);
    });

    testWidgets('tapping a node shows full label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapView(
              nodes: [
                {'id': 1, 'label': 'Machine Learning Basics Details'},
              ],
              edges: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Machine Learning B..'));
      await tester.pumpAndSettle();
      expect(find.text('Machine Learning Basics Details'), findsOneWidget);
    });

    testWidgets('handles many nodes without crash', (tester) async {
      final nodes = List.generate(20, (i) => {'id': i, 'label': 'Node $i'});
      final edges = List.generate(19, (i) => {'from': 0, 'to': i + 1});
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapView(nodes: nodes, edges: edges),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Node 0'), findsOneWidget);
    });
  });

  // ═════════════ 9. CodeSandboxTab Widget ═════════════
  group('CodeSandboxTab Widget', () {
    testWidgets('renders empty state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CodeSandboxTab(codeSnippets: [])),
        ),
      );
      expect(find.text('No code snippets found.'), findsOneWidget);
      expect(find.byIcon(Icons.code_off), findsOneWidget);
    });

    testWidgets('renders Python snippet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeSandboxTab(
              codeSnippets: [
                {
                  'title': 'Sort',
                  'language': 'python',
                  'code_content': 'sorted([3,1])',
                },
              ],
            ),
          ),
        ),
      );
      expect(find.text('Sort'), findsOneWidget);
      expect(find.text('PYTHON'), findsOneWidget);
      expect(find.text('sorted([3,1])'), findsOneWidget);
    });

    testWidgets('renders Java snippet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeSandboxTab(
              codeSnippets: [
                {
                  'title': 'Main',
                  'language': 'java',
                  'code_content': 'public static void main(){}',
                },
              ],
            ),
          ),
        ),
      );
      expect(find.text('JAVA'), findsOneWidget);
    });

    testWidgets('renders JavaScript snippet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeSandboxTab(
              codeSnippets: [
                {
                  'title': 'Log',
                  'language': 'javascript',
                  'code_content': 'console.log("hi")',
                },
              ],
            ),
          ),
        ),
      );
      expect(find.text('JAVASCRIPT'), findsOneWidget);
    });

    testWidgets('renders multiple snippets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeSandboxTab(
              codeSnippets: [
                {'title': 'A', 'language': 'python', 'code_content': 'x=1'},
                {'title': 'B', 'language': 'java', 'code_content': 'int x=1;'},
              ],
            ),
          ),
        ),
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('handles missing fields gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CodeSandboxTab(codeSnippets: [{}])),
        ),
      );
      expect(find.text('Code Snippet'), findsOneWidget);
      expect(find.text('TEXT'), findsOneWidget);
    });

    testWidgets('has copy button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeSandboxTab(
              codeSnippets: [
                {
                  'title': 'Test',
                  'language': 'dart',
                  'code_content': 'void main(){}',
                },
              ],
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('renders SQL snippet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeSandboxTab(
              codeSnippets: [
                {
                  'title': 'Query',
                  'language': 'sql',
                  'code_content': 'SELECT * FROM users;',
                },
              ],
            ),
          ),
        ),
      );
      expect(find.text('SQL'), findsOneWidget);
    });
  });

  // ═════════════ 10. Tab Logic Tests ═════════════
  group('Tab Logic', () {
    test('5 tabs when code snippets exist', () {
      final r = AnalysisResult.fromJson({
        'code_snippets': [
          {'title': 'X', 'language': 'python', 'code_content': 'x'},
        ],
      });
      expect(r.codeSnippets.isNotEmpty ? 5 : 4, 5);
    });

    test('4 tabs when no code snippets', () {
      final r = AnalysisResult.fromJson({'code_snippets': []});
      expect(r.codeSnippets.isNotEmpty ? 5 : 4, 4);
    });

    test('4 tabs when code_snippets field missing', () {
      final r = AnalysisResult.fromJson({});
      expect(r.codeSnippets.isNotEmpty ? 5 : 4, 4);
    });
  });

  // ═════════════ 11. Edge Cases ═════════════
  group('Edge Cases', () {
    test('AnalysisResult with special characters in summary', () {
      final r = AnalysisResult.fromJson({
        'summary': 'He said "hello" & she said <goodbye>',
      });
      expect(r.summary, contains('"hello"'));
    });

    test('AnalysisResult with unicode', () {
      final r = AnalysisResult.fromJson({'summary': '数学 📚 مرحبا 🧠'});
      expect(r.summary, contains('📚'));
    });

    test('FlashcardData with markdown content', () {
      final c = FlashcardData.fromJson({
        'front': '**Bold** and _italic_',
        'back': '```python\nprint("hello")\n```',
      });
      expect(c.front, contains('**Bold**'));
      expect(c.back, contains('```python'));
    });

    test('Profile interests preserves order', () {
      final p = Profile.fromJson({
        'id': 'u1',
        'interests': ['C', 'A', 'B'],
      });
      expect(p.interests, ['C', 'A', 'B']);
    });

    test('QuizQuestion with 2 options (true/false)', () {
      final q = QuizQuestion.fromJson({
        'question': 'True or false?',
        'options': ['True', 'False'],
        'correct_answer': 'True',
      });
      expect(q.options.length, 2);
    });
  });
}
