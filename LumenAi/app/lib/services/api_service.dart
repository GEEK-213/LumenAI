import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/data_models.dart';

class ApiService {
  final SupabaseClient _supabase = Supabase.instance.client;
  // Android Emulator: 10.0.2.2, iOS/Web: localhost or 127.0.0.1
  // Ngrok Demo URL
  final String baseUrl = 'https://graeme-weathered-jackie.ngrok-free.dev';

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

  Future<AnalysisResult> processLecture({
    required File audioFile,
    required String userId,
    required String subjectId,
    String? unitId,
    String? title,
  }) async {
    final uri = Uri.parse('$baseUrl/analysis/process');
    final request = http.MultipartRequest('POST', uri);

    request.fields['subject_id'] = subjectId;
    if (unitId != null && unitId.isNotEmpty) {
      request.fields['unit_id'] = unitId;
    }
    request.fields['user_id'] = userId;
    if (title != null) request.fields['title'] = title;

    request.files.add(
      await http.MultipartFile.fromPath('file', audioFile.path),
    );

    print("🚀 Sending request to $uri with Unit ID: $unitId");

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final lectureId = json['lecture_id'];
        if (lectureId == null) {
          throw Exception('Lecture processed but no ID returned from API.');
        }

        print("✅ Analysis Complete: $lectureId");

        // Fetch the full lecture data from Supabase to get the JSON artifacts
        // Or closely parse the response if the backend returns everything.
        // For now, let's fetch the lecture from DB to be safe/consistent
        // OR just parse what we can if backend was updated to return full result.
        // Checking backend... backend returns {status, lecture_id, summary_preview}.

        // So we must fetch the full lecture to get the artifacts
        return await _fetchLectureResult(lectureId.toString());
      } else {
        throw Exception(
          'Failed to process lecture: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print("❌ API Error: $e");
      rethrow;
    }
  }

  Future<void> uploadSyllabus({
    required File documentFile,
    required String userId,
    required String subjectId,
    String? unitId,
    String? title,
  }) async {
    final uri = Uri.parse('$baseUrl/ingestion/upload');
    final request = http.MultipartRequest('POST', uri);

    request.fields['user_id'] = userId;
    request.fields['subject_id'] = subjectId;
    if (unitId != null && unitId.isNotEmpty) {
      request.fields['unit_id'] = unitId;
    }
    if (title != null) request.fields['title'] = title;

    request.files.add(
      await http.MultipartFile.fromPath('file', documentFile.path),
    );

    print("🚀 Sending syllabus upload to $uri with Unit ID: $unitId");

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print("✅ Syllabus Upload Complete");
      } else {
        throw Exception(
          'Failed to upload syllabus: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print("❌ API Error: $e");
      rethrow;
    }
  }

  Future<AnalysisResult> _fetchLectureResult(String lectureId) async {
    final response = await _supabase
        .from('lectures')
        .select('raw_analysis')
        .eq('id', lectureId)
        .single();

    // Also fetch the background tasks data from related tables so we can inject them back into the object!
    final quizRes = await _supabase
        .from('quiz_questions')
        .select()
        .eq('lecture_id', lectureId);
    final fcRes = await _supabase
        .from('flashcards')
        .select()
        .eq('lecture_id', lectureId);

    if (response['raw_analysis'] != null) {
      final raw = response['raw_analysis'];
      final rawMap = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw);

      // Inject background tasks back into the JSON to reconstruct the full AnalysisResult
      if (quizRes.isNotEmpty) {
        rawMap['quiz_questions'] = quizRes;
      }
      if (fcRes.isNotEmpty) {
        rawMap['flashcards'] = fcRes;
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
      print("Failed to get analysis result: $e");
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
    final response = await http.delete(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete lecture: ${response.statusCode}');
    }
  }

  Future<void> renameLecture(String lectureId, String newTitle) async {
    final uri = Uri.parse('$baseUrl/analysis/lecture/$lectureId');
    final request = http.MultipartRequest('PUT', uri);
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
    final response = await http.delete(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete syllabus: ${response.statusCode}');
    }
  }

  Future<void> renameSyllabus(String syllabusId, String newTitle) async {
    final uri = Uri.parse('$baseUrl/ingestion/syllabus/$syllabusId');
    final request = http.MultipartRequest('PUT', uri);
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
}
