import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Profile?> getProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return Profile.fromJson(data);
    } catch (e) {
     
      print('Error fetching profile: $e');
      return null;
    }
  }

  Future<bool> updateProfile(Profile profile) async {
    try {
      await _supabase.from('profiles').upsert(profile.toJson());
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  Future<bool> updateInterests(String userId, List<String> interests) async {
    try {
      await _supabase
          .from('profiles')
          .update({'interests': interests})
          .eq('id', userId);
      return true;
    } catch (e) {
      print('Error updating interests: $e');
      return false;
    }
  }

  Future<String?> uploadAvatar(String userId, String filePath) async {
    try {
      final file = File(filePath);
      final fileExt = filePath.split('.').last;

      // Create a unique filename to prevent caching issues
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload to 'avatars' bucket
      await _supabase.storage
          .from('avatars')
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      // Update profile with new avatar URL
      await _supabase
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);

      return publicUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }
}
