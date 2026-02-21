import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/data_models.dart';

class ApiService {
  final SupabaseClient _supabase = Supabase.instance.client;
  // Android Emulator: 10.0.2.2, iOS/Web: localhost or 127.0.0.1
  // For physical device, use your machine's local IP (e.g., 192.168.1.X)
  final String _baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:8001'
      : 'http://127.0.0.1:8001';

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
    String? unitId,
    String? title,
  }) async {
    final uri = Uri.parse('$_baseUrl/analysis/process');
    final request = http.MultipartRequest('POST', uri);

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
        print("✅ Analysis Complete: ${json['lecture_id']}");

        // Fetch the full lecture data from Supabase to get the JSON artifacts
        // Or closely parse the response if the backend returns everything.
        // For now, let's fetch the lecture from DB to be safe/consistent
        // OR just parse what we can if backend was updated to return full result.
        // Checking backend... backend returns {status, lecture_id, summary_preview}.

        // So we must fetch the full lecture to get the artifacts
        return await _fetchLectureResult(json['lecture_id']);
      } else {
        throw Exception('Failed to process lecture: ${response.body}');
      }
    } catch (e) {
      print("❌ API Error: $e");
      rethrow;
    }
  }

  Future<AnalysisResult> _fetchLectureResult(String lectureId) async {
    // We need to join the artifacts.
    // Actually, to display the *immediate* result, it might be easier to just
    // fetch the 'raw_analysis' column from the 'lectures' table which stores the full JSON.

    final response = await _supabase
        .from('lectures')
        .select('raw_analysis')
        .eq('id', lectureId)
        .single();

    if (response['raw_analysis'] != null) {
      final raw = response['raw_analysis'];
      print("📊 raw_analysis type: ${raw.runtimeType}");
      if (raw is Map) {
        print("📊 raw_analysis keys: ${raw.keys.toList()}");
        print(
          "📊 summary preview: ${raw['summary']?.toString().substring(0, 100)}",
        );
        print("📊 topics: ${raw['topics']}");
      } else {
        print(
          "📊 raw_analysis value (first 200): ${raw.toString().substring(0, 200)}",
        );
      }
      return AnalysisResult.fromJson(
        raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw),
      );
    } else {
      throw Exception("Lecture processed but no analysis data found.");
    }
  }
}
