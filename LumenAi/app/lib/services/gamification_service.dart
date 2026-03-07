import 'package:supabase_flutter/supabase_flutter.dart';

class GamificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch the current user's profile, creating one if it doesn't exist
  Future<Map<String, dynamic>> fetchProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not signed in");

    try {
      final response = await _supabase
          .from('lumen_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        return response;
      }

      // Profile doesn't exist yet, create it
      final newProfile = {
        'user_id': user.id,
        'lumen_coins': 0,
        'xp': 0,
        'streak_days': 0,
        'rank_title': 'Novice Scholar',
      };
      await _supabase.from('lumen_profiles').insert(newProfile);
      return newProfile;
    } catch (e) {
      print('❌ Error fetching profile: $e');
      rethrow;
    }
  }

  /// Award Lumen Coins to the user
  Future<void> awardCoins(int amount, {String reason = "Activity"}) async {
    final user = _supabase.auth.currentUser;
    if (user == null || amount <= 0) return;

    try {
      final profile = await fetchProfile();
      final currentCoins = profile['lumen_coins'] as int? ?? 0;
      final currentXp = profile['xp'] as int? ?? 0;

      final newCoins = currentCoins + amount;
      final newXp = currentXp + amount; // 1 coin = 1 XP for simplicity

      // Calculate rank based on XP
      String rank = 'Novice Scholar';
      if (newXp >= 1000)
        rank = 'Lumen Grandmaster';
      else if (newXp >= 500)
        rank = 'Expert Scholar';
      else if (newXp >= 200)
        rank = 'Adept';
      else if (newXp >= 50)
        rank = 'Apprentice';

      // Update the database (ideally via an RPC for race conditions, but this is fine for now)
      await _supabase
          .from('lumen_profiles')
          .update({
            'lumen_coins': newCoins,
            'xp': newXp,
            'rank_title': rank,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', user.id);

      print('✨ Awarded $amount Lumen Coins for $reason! New Total: $newCoins');
    } catch (e) {
      print('❌ Error awarding coins: $e');
    }
  }
}
