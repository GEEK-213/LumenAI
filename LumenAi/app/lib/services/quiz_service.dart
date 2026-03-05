import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for quiz attempt tracking — saves scores and fetches history.
class QuizService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Save a quiz attempt after the user completes all questions.
  Future<void> saveAttempt({
    required String lectureId,
    required int score,
    required int total,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('quiz_attempts').insert({
      'user_id': userId,
      'lecture_id': lectureId,
      'score': score,
      'total': total,
    });
  }

  /// Fetch quiz attempt history for a specific lecture, newest first.
  Future<List<Map<String, dynamic>>> getHistory(String lectureId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('quiz_attempts')
        .select()
        .eq('lecture_id', lectureId)
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(10);

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Get the best score for a lecture.
  Future<int?> getBestScore(String lectureId) async {
    final history = await getHistory(lectureId);
    if (history.isEmpty) return null;

    int best = 0;
    for (final attempt in history) {
      final score = attempt['score'] as int? ?? 0;
      if (score > best) best = score;
    }
    return best;
  }
}
