import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../models/data_models.dart';

class MultipartRequestWithProgress extends http.MultipartRequest {
  MultipartRequestWithProgress(String method, Uri url, {this.onProgress})
    : super(method, url);

  final void Function(int bytes, int totalBytes)? onProgress;

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    if (onProgress == null) return byteStream;

    final total = contentLength;
    int bytes = 0;

    final transformer = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (data, sink) {
        bytes += data.length;
        if (onProgress != null) onProgress!(bytes, total);
        sink.add(data);
      },
    );

    return http.ByteStream(byteStream.transform(transformer));
  }
}

class ApiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Expose the Supabase client for authentication checks
  SupabaseClient get supabase => _supabase;

  final String baseUrl = AppConfig.apiBaseUrl;

  // --- Auth Helper ---

  /// Returns the current Supabase session's access token.
  /// Throws if user is not authenticated.
  Future<Map<String, String>> _authHeaders() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('Not authenticated. Please sign in.');
    }
    return {'Authorization': 'Bearer ${session.accessToken}'};
  }

  /// Public accessor for auth headers (used by chat page for direct HTTP calls).
  Future<Map<String, String>> get authHeaders => _authHeaders();

  /// Convenience: auth headers merged with JSON content-type.
  Future<Map<String, String>> _authJsonHeaders() async {
    final auth = await _authHeaders();
    return {...auth, 'Content-Type': 'application/json'};
  }

  // --- Supabase Direct Queries (auth handled by Supabase SDK) ---

  Future<List<Subject>> getSubjects() async {
    final response = await _supabase
        .from('subjects')
        .select()
        .order('name', ascending: true);
    return (response as List).map((e) => Subject.fromJson(e)).toList();
  }

  Future<List<Unit>> getUnits(String subjectId) async {
    final response = await _supabase
        .from('units')
        .select()
        .eq('subject_id', subjectId)
        .order('unit_number', ascending: true);
    return (response as List).map((e) => Unit.fromJson(e)).toList();
  }

  // --- API Calls (auth via JWT header) ---

  Future<AnalysisResult> processLecture({
    required File audioFile,
    required String userId,
    required String subjectId,
    String? unitId,
    String? title,
    void Function(int sent, int total)? onProgress,
  }) async {
    final uri = Uri.parse('$baseUrl/analysis/process');
    final request = MultipartRequestWithProgress(
      'POST',
      uri,
      onProgress: onProgress,
    );

    // Auth header
    final headers = await _authHeaders();
    request.headers.addAll(headers);

    request.fields['subject_id'] = subjectId;
    if (unitId != null && unitId.isNotEmpty) {
      request.fields['unit_id'] = unitId;
    }
    if (title != null) request.fields['title'] = title;

    request.files.add(
      await http.MultipartFile.fromPath('file', audioFile.path),
    );

    debugPrint("🚀 Sending request to $uri with Unit ID: $unitId");

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final lectureId = json['lecture_id'];
        if (lectureId == null) {
          throw Exception('Lecture processed but no ID returned from API.');
        }

        debugPrint("✅ Analysis Complete: $lectureId");
        return await _fetchLectureResult(lectureId.toString());
      } else {
        throw Exception(
          'Failed to process lecture: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint("❌ API Error: $e");
      rethrow;
    }
  }

  Future<void> uploadSyllabus({
    required File documentFile,
    required String userId,
    required String subjectId,
    String? unitId,
    String? title,
    void Function(int sent, int total)? onProgress,
  }) async {
    final uri = Uri.parse('$baseUrl/ingestion/upload');
    final request = MultipartRequestWithProgress(
      'POST',
      uri,
      onProgress: onProgress,
    );

    // Auth header
    final headers = await _authHeaders();
    request.headers.addAll(headers);

    request.fields['subject_id'] = subjectId;
    if (unitId != null && unitId.isNotEmpty) {
      request.fields['unit_id'] = unitId;
    }
    if (title != null) request.fields['title'] = title;

    request.files.add(
      await http.MultipartFile.fromPath('file', documentFile.path),
    );

    debugPrint("🚀 Sending syllabus upload to $uri with Unit ID: $unitId");

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        debugPrint("✅ Syllabus Upload Complete");
      } else {
        throw Exception(
          'Failed to upload syllabus: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint("❌ API Error: $e");
      rethrow;
    }
  }

  Future<AnalysisResult> _fetchLectureResult(String lectureId) async {
    final response = await _supabase
        .from('lectures')
        .select('raw_analysis')
        .eq('id', lectureId)
        .single();

    final quizRes = await _supabase
        .from('quiz_questions')
        .select()
        .eq('lecture_id', lectureId);
    final fcRes = await _supabase
        .from('flashcards')
        .select()
        .eq('lecture_id', lectureId);
    final mmRes = await _supabase
        .from('mind_maps')
        .select()
        .eq('lecture_id', lectureId);

    if (response['raw_analysis'] != null) {
      final raw = response['raw_analysis'];
      final rawMap = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw);

      rawMap['lecture_id'] = lectureId;

      if (quizRes.isNotEmpty) {
        rawMap['quiz_questions'] = quizRes;
      }
      if (fcRes.isNotEmpty) {
        rawMap['flashcards'] = fcRes;
      }
      // Merge mind map from DB if not in raw_analysis
      if ((rawMap['mind_map'] == null ||
              (rawMap['mind_map'] is Map &&
                  (rawMap['mind_map']['nodes'] as List?)?.isEmpty == true)) &&
          mmRes.isNotEmpty) {
        rawMap['mind_map'] = {
          'nodes': mmRes.first['nodes'] ?? [],
          'edges': mmRes.first['edges'] ?? [],
        };
      }

      return AnalysisResult.fromJson(rawMap);
    } else {
      throw Exception("Lecture processed but no analysis data found.");
    }
  }

  Future<AnalysisResult?> getAnalysisResult(String lectureId) async {
    try {
      return await _fetchLectureResult(lectureId);
    } catch (e) {
      debugPrint("Failed to get analysis result: $e");
      return null;
    }
  }

  // --- CRUD Operations ---

  /// Fetch all lectures for a specific subject
  Future<List<Map<String, dynamic>>> getSubjectLectures(
    String subjectId,
  ) async {
    final response = await _supabase
        .from('lectures')
        .select()
        .eq('subject_id', subjectId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Fetch all syllabus sources for a specific subject
  Future<List<Map<String, dynamic>>> getSubjectSyllabi(String subjectId) async {
    final response = await _supabase
        .from('syllabus_sources')
        .select()
        .eq('subject_id', subjectId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> deleteLecture(String lectureId) async {
    final uri = Uri.parse('$baseUrl/analysis/lecture/$lectureId');
    final headers = await _authHeaders();
    final response = await http.delete(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete lecture: ${response.statusCode}');
    }
  }

  Future<void> renameLecture(String lectureId, String newTitle) async {
    final uri = Uri.parse('$baseUrl/analysis/lecture/$lectureId');
    final request = http.MultipartRequest('PUT', uri);
    final headers = await _authHeaders();
    request.headers.addAll(headers);
    request.fields['new_title'] = newTitle;
    final streamedResponse = await request.send();
    if (streamedResponse.statusCode != 200) {
      throw Exception(
        'Failed to rename lecture: ${streamedResponse.statusCode}',
      );
    }
  }

  Future<void> deleteSyllabus(String syllabusId) async {
    final uri = Uri.parse('$baseUrl/ingestion/syllabus/$syllabusId');
    final headers = await _authHeaders();
    final response = await http.delete(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete syllabus: ${response.statusCode}');
    }
  }

  Future<void> renameSyllabus(String syllabusId, String newTitle) async {
    final uri = Uri.parse('$baseUrl/ingestion/syllabus/$syllabusId');
    final request = http.MultipartRequest('PUT', uri);
    final headers = await _authHeaders();
    request.headers.addAll(headers);
    request.fields['new_title'] = newTitle;
    final streamedResponse = await request.send();
    if (streamedResponse.statusCode != 200) {
      throw Exception(
        'Failed to rename syllabus: ${streamedResponse.statusCode}',
      );
    }
  }

  /// Fetch all extracted tasks (Deadlines) for a specific user
  Future<List<Map<String, dynamic>>> getExtractedTasks(String userId) async {
    final response = await _supabase
        .from('extracted_tasks')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Manually sync Google Classroom materials for a specific subject
  Future<void> syncClassroomSubject(String subjectId, String userId) async {
    final uri = Uri.parse('$baseUrl/classroom/sync_subject');
    final headers = await _authJsonHeaders();
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({'user_id': userId, 'subject_id': subjectId}),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to sync classroom: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// On-demand AI analysis for a previously pulled (un-analyzed) lecture.
  /// Triggered by the 'Make it Smart' button.
  Future<Map<String, dynamic>> analyzeLecture(String lectureId) async {
    final uri = Uri.parse('$baseUrl/analysis/analyze_lecture/$lectureId');
    final headers = await _authHeaders();
    final response = await http.post(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to analyze lecture: ${response.statusCode} - ${response.body}',
      );
    }
    return jsonDecode(response.body);
  }

  /// Gamification: Generates 5 novel MCQs avoiding existing ones on the backend.
  Future<List<QuizQuestion>> generateDynamicQuiz(String lectureId) async {
    final uri = Uri.parse('$baseUrl/analysis/lecture/$lectureId/quiz/dynamic');
    final headers = await _authHeaders();
    final response = await http.post(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to generate dynamic quiz: ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body);
    final data = json['data'] as List;
    return data.map((e) => QuizQuestion.fromJson(e)).toList();
  }

  /// Gamification: Generates 5 novel Flashcards avoiding existing concepts.
  Future<List<FlashcardData>> generateDynamicFlashcards(
    String lectureId,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/analysis/lecture/$lectureId/flashcards/dynamic',
    );
    final headers = await _authHeaders();
    final response = await http.post(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to generate dynamic flashcards: ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body);
    final data = json['data'] as List;
    return data.map((e) => FlashcardData.fromJson(e)).toList();
  }

  // --- Phase 5: Next-Gen AI Learning (LumenCast Podcasts) ---

  /// Requests the backend to generate a TTS podcast audio file for a given lecture.
  Future<LumenCast> generateLumenCast(String lectureId) async {
    final uri = Uri.parse(
      '$baseUrl/analysis/lecture/$lectureId/podcast/generate',
    );
    final headers = await _authHeaders();
    final response = await http.post(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to generate LumenCast: ${response.statusCode} - ${response.body}',
      );
    }

    final json = jsonDecode(response.body);
    return LumenCast.fromJson(json['data']);
  }

  /// Fetches existing generated podcasts from Supabase for a given lecture.
  Future<List<LumenCast>> getLumenCasts(String lectureId) async {
    final response = await _supabase
        .from('lumen_casts')
        .select()
        .eq('lecture_id', lectureId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => LumenCast.fromJson(e)).toList();
  }

  // --- Phase 5: Smart Syllabus Auto-Mapping ---

  /// Fetches an AI-generated mapping suggestion for an unmapped lecture.
  Future<Map<String, dynamic>?> getAutoMapSuggestion(String lectureId) async {
    final uri = Uri.parse('$baseUrl/mapping/suggest/$lectureId');
    final headers = await _authHeaders();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get mapping suggestion: ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body);
    if (json['status'] == 'no_suggestion') return null;
    return json['data'] as Map<String, dynamic>;
  }

  /// Applies a unit mapping to a lecture (user accepts the suggestion or picks manually).
  Future<void> applyAutoMap(String lectureId, String unitId) async {
    final uri = Uri.parse('$baseUrl/mapping/apply/$lectureId');
    final headers = await _authHeaders();
    final response = await http.post(
      uri,
      headers: {
        ...headers,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'unit_id': unitId},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to apply mapping: ${response.statusCode}');
    }
  }

  /// Forces a fresh AI re-mapping attempt for a lecture.
  Future<Map<String, dynamic>?> remapLecture(String lectureId) async {
    final uri = Uri.parse('$baseUrl/mapping/remap/$lectureId');
    final headers = await _authHeaders();
    final response = await http.post(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to remap lecture: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);
    if (json['status'] == 'no_suggestion') return null;
    return json['data'] as Map<String, dynamic>;
  }

  // --- Phase 5: Infinite Spatial Canvas ---

  /// Fetches all canvas pins for a subject.
  Future<List<Map<String, dynamic>>> getCanvasPins(String subjectId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await _supabase
        .from('canvas_pins')
        .select()
        .eq('user_id', userId)
        .eq('subject_id', subjectId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Saves a new pin to the canvas.
  Future<Map<String, dynamic>> saveCanvasPin({
    required String subjectId,
    required String lectureId,
    required String pinType,
    required Map<String, dynamic> content,
    required double x,
    required double y,
    String color = '#6C5CE7',
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    final response = await _supabase
        .from('canvas_pins')
        .insert({
          'user_id': userId,
          'subject_id': subjectId,
          'lecture_id': lectureId,
          'pin_type': pinType,
          'content': content,
          'x': x,
          'y': y,
          'color': color,
        })
        .select()
        .single();
    return response;
  }

  /// Updates the position of a canvas pin.
  Future<void> updatePinPosition(String pinId, double x, double y) async {
    await _supabase
        .from('canvas_pins')
        .update({'x': x, 'y': y})
        .eq('id', pinId);
  }

  /// Deletes a canvas pin.
  Future<void> deleteCanvasPin(String pinId) async {
    await _supabase.from('canvas_pins').delete().eq('id', pinId);
  }
}
