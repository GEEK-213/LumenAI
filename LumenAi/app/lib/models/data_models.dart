class Subject {
  final String id;
  final String name;

  Subject({required this.id, required this.name});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(id: json['id'], name: json['name']);
  }
}

class Unit {
  final String id;
  final String name;
  final String subjectId;

  Unit({required this.id, required this.name, required this.subjectId});

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'],
      name: json['name'],
      subjectId: json['subject_id'],
    );
  }
}

class AnalysisResult {
  final String summary;
  final List<String> topics;
  final List<FlashcardData> flashcards;
  final List<QuizQuestion> quizQuestions;
  final MindMapData? mindMap;
  final List<String> tasks;
  final List<String> teacherQuestions;
  final String transcript;

  AnalysisResult({
    required this.summary,
    required this.topics,
    required this.flashcards,
    required this.quizQuestions,
    this.mindMap,
    required this.tasks,
    required this.teacherQuestions,
    required this.transcript,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      summary: json['summary'] ?? '',
      topics: List<String>.from(json['topics'] ?? []),
      flashcards: (json['flashcards'] as List?)
              ?.map((e) => FlashcardData.fromJson(e))
              .toList() ??
          [],
      quizQuestions: (json['quiz_questions'] as List?)
              ?.map((e) => QuizQuestion.fromJson(e))
              .toList() ??
          [],
      mindMap:
          json['mind_map'] != null ? MindMapData.fromJson(json['mind_map']) : null,
      tasks: (json['extracted_tasks'] as List?)
              ?.map((e) => e['title'].toString())
              .toList() ??
          [],
      teacherQuestions: List<String>.from(json['teacher_questions'] ?? []),
      transcript: json['transcript'] ?? '',
    );
  }
}

class FlashcardData {
  final String front;
  final String back;

  FlashcardData({required this.front, required this.back});

  factory FlashcardData.fromJson(Map<String, dynamic> json) {
    return FlashcardData(front: json['front'], back: json['back']);
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'],
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correct_answer'],
      explanation: json['explanation'] ?? '',
    );
  }
}

class MindMapData {
  final List<Map<String, dynamic>> nodes;
  final List<Map<String, dynamic>> edges;

  MindMapData({required this.nodes, required this.edges});

  factory MindMapData.fromJson(Map<String, dynamic> json) {
    return MindMapData(
      nodes: List<Map<String, dynamic>>.from(json['nodes'] ?? []),
      edges: List<Map<String, dynamic>>.from(json['edges'] ?? []),
    );
  }
}
