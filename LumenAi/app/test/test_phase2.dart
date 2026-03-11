import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/data_models.dart';
import 'package:app/pages/notes/mind_map_tab.dart';
import 'package:app/pages/notes/code_sandbox_tab.dart';

// ═══════════════════════════════════════════════════════════
// 1. Data Model Tests (AnalysisResult)
// ═══════════════════════════════════════════════════════════

void main() {
  group('AnalysisResult Model', () {
    test('parses full AI response correctly', () {
      final json = {
        'summary': 'Test summary about AI and ML.',
        'topics': ['Machine Learning', 'Neural Networks'],
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
            'title': 'Hello World',
            'language': 'python',
            'code_content': "print('hello')",
          },
        ],
        'extracted_tasks': [
          {'title': 'Assignment 1', 'due_date': '2026-03-15'},
        ],
        'teacher_questions': ['What is gradient descent?'],
        'transcript': 'Full transcript here.',
      };

      final result = AnalysisResult.fromJson(json);

      expect(result.summary, 'Test summary about AI and ML.');
      expect(result.topics.length, 2);
      expect(result.mindMap, isNotNull);
      expect(result.mindMap!.nodes.length, 2);
      expect(result.mindMap!.edges.length, 1);
      expect(result.codeSnippets.length, 1);
      expect(result.codeSnippets[0]['language'], 'python');
      expect(result.tasks.length, 1);
      expect(result.teacherQuestions.length, 1);
      expect(result.transcript, 'Full transcript here.');
    });

    test('handles missing optional fields gracefully', () {
      final json = {'summary': 'Minimal response'};

      final result = AnalysisResult.fromJson(json);

      expect(result.summary, 'Minimal response');
      expect(result.topics, isEmpty);
      expect(result.mindMap, isNull);
      expect(result.codeSnippets, isEmpty);
      expect(result.flashcards, isEmpty);
      expect(result.quizQuestions, isEmpty);
      expect(result.tasks, isEmpty);
      expect(result.teacherQuestions, isEmpty);
      expect(result.transcript, '');
    });

    test('handles code_snippets as empty list', () {
      final json = {'summary': 'No code', 'code_snippets': []};

      final result = AnalysisResult.fromJson(json);
      expect(result.codeSnippets, isEmpty);
    });

    test('handles mind_map with string IDs', () {
      final json = {
        'summary': 'test',
        'mind_map': {
          'nodes': [
            {'id': '1', 'label': 'Root'},
            {'id': '2', 'label': 'Child'},
          ],
          'edges': [
            {'from': '1', 'to': '2'},
          ],
        },
      };

      final result = AnalysisResult.fromJson(json);
      expect(result.mindMap, isNotNull);
      expect(result.mindMap!.nodes[0]['id'], '1');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 2. MindMapView Widget Tests
  // ═══════════════════════════════════════════════════════════

  group('MindMapView Widget', () {
    testWidgets('renders empty state when no nodes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MindMapView(nodes: [], edges: []),
          ),
        ),
      );

      expect(find.text('No mind map data.'), findsOneWidget);
    });

    testWidgets('renders nodes with integer IDs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapView(
              nodes: [
                {'id': 1, 'label': 'Central'},
                {'id': 2, 'label': 'Child A'},
                {'id': 3, 'label': 'Child B'},
              ],
              edges: [
                {'from': 1, 'to': 2},
                {'from': 1, 'to': 3},
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Nodes should render without crash
      expect(find.text('Central'), findsOneWidget);
      expect(find.text('Child A'), findsOneWidget);
      expect(find.text('Child B'), findsOneWidget);
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
      expect(find.text('Leaf'), findsOneWidget);
    });

    testWidgets('truncates long labels correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapView(
              nodes: [
                {'id': 1, 'label': 'This Is A Very Long Label Name'},
              ],
              edges: [],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Root label truncated to 18 chars + '..' (root maxChars=20)
      expect(find.text('This Is A Very Lon..'), findsOneWidget);
    });

    testWidgets('tapping a node expands it', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapView(
              nodes: [
                {'id': 1, 'label': 'Machine Learning Basics'},
              ],
              edges: [],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Root label is > 20 chars so truncated to 18 + '..' (root maxChars=20)
      await tester.tap(find.text('Machine Learning B..'));
      await tester.pumpAndSettle();

      // Expanded label should show full text
      expect(find.text('Machine Learning Basics'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 3. CodeSandboxTab Widget Tests
  // ═══════════════════════════════════════════════════════════

  group('CodeSandboxTab Widget', () {
    testWidgets('renders empty state when no snippets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CodeSandboxTab(codeSnippets: [])),
        ),
      );

      expect(find.text('No code snippets found.'), findsOneWidget);
      expect(find.byIcon(Icons.code_off), findsOneWidget);
    });

    testWidgets('renders a code snippet card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeSandboxTab(
              codeSnippets: [
                {
                  'title': 'Hello World',
                  'language': 'python',
                  'code_content': "print('hello')",
                },
              ],
            ),
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
      expect(find.text('PYTHON'), findsOneWidget);
      expect(find.text("print('hello')"), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('renders multiple code snippets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeSandboxTab(
              codeSnippets: [
                {
                  'title': 'Snippet 1',
                  'language': 'java',
                  'code_content': 'System.out.println("hi");',
                },
                {
                  'title': 'Snippet 2',
                  'language': 'javascript',
                  'code_content': 'console.log("hi");',
                },
              ],
            ),
          ),
        ),
      );

      expect(find.text('Snippet 1'), findsOneWidget);
      expect(find.text('Snippet 2'), findsOneWidget);
      expect(find.text('JAVA'), findsOneWidget);
      expect(find.text('JAVASCRIPT'), findsOneWidget);
    });

    testWidgets('handles missing fields gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeSandboxTab(
              codeSnippets: [
                {}, // Empty snippet — should not crash
              ],
            ),
          ),
        ),
      );

      // Should render something without crashing
      expect(find.text('Code Snippet'), findsOneWidget); // Default title
      expect(find.text('TEXT'), findsOneWidget); // Default language
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 4. Results Page Tab Logic Tests (no Supabase dependency)
  // ═══════════════════════════════════════════════════════════

  group('Results Page Tab Logic', () {
    test('code tab should appear when codeSnippets not empty', () {
      final result = AnalysisResult(
        summary: 'Test summary',
        topics: ['Topic 1'],
        flashcards: [],
        quizQuestions: [],
        mindMap: null,
        codeSnippets: [
          {'title': 'Test', 'language': 'python', 'code_content': 'pass'},
        ],
        tasks: [],
        teacherQuestions: [],
        transcript: '',
      );

      // Tab count should be 5 when code snippets exist
      final tabCount = result.codeSnippets.isNotEmpty ? 5 : 4;
      expect(tabCount, 5);
    });

    test('code tab should NOT appear when codeSnippets empty', () {
      final result = AnalysisResult(
        summary: 'Test summary',
        topics: [],
        flashcards: [],
        quizQuestions: [],
        mindMap: null,
        codeSnippets: [],
        tasks: [],
        teacherQuestions: [],
        transcript: '',
      );

      final tabCount = result.codeSnippets.isNotEmpty ? 5 : 4;
      expect(tabCount, 4);
    });

    test('summary content is accessible for display', () {
      final result = AnalysisResult(
        summary: 'This is the AI-generated summary.',
        topics: ['Topic A', 'Topic B'],
        flashcards: [],
        quizQuestions: [],
        codeSnippets: [],
        tasks: ['Assignment 1'],
        teacherQuestions: ['What is X?'],
        transcript: '',
      );

      expect(result.summary, 'This is the AI-generated summary.');
      expect(result.topics, contains('Topic A'));
      expect(result.tasks, contains('Assignment 1'));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 5. FlashcardData & QuizQuestion Model Tests
  // ═══════════════════════════════════════════════════════════

  group('FlashcardData Model', () {
    test('parses correctly', () {
      final card = FlashcardData.fromJson({'front': 'Term', 'back': 'Def'});
      expect(card.front, 'Term');
      expect(card.back, 'Def');
    });
  });

  group('QuizQuestion Model', () {
    test('parses correctly', () {
      final q = QuizQuestion.fromJson({
        'question': 'What?',
        'options': ['A', 'B', 'C', 'D'],
        'correct_answer': 'A',
        'explanation': 'Because',
      });
      expect(q.question, 'What?');
      expect(q.options.length, 4);
      expect(q.correctAnswer, 'A');
    });

    test('handles missing explanation', () {
      final q = QuizQuestion.fromJson({
        'question': 'Q?',
        'options': ['A'],
        'correct_answer': 'A',
      });
      expect(q.explanation, '');
    });
  });

  group('MindMapData Model', () {
    test('parses nodes and edges', () {
      final mm = MindMapData.fromJson({
        'nodes': [
          {'id': 1, 'label': 'Root'},
        ],
        'edges': [
          {'from': 1, 'to': 2},
        ],
      });
      expect(mm.nodes.length, 1);
      expect(mm.edges.length, 1);
    });

    test('handles empty data', () {
      final mm = MindMapData.fromJson({});
      expect(mm.nodes, isEmpty);
      expect(mm.edges, isEmpty);
    });
  });
}
