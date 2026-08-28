import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    return _client
        .from('users_profiles')
        .select(
          'id, display_name, avatar_url, date_of_birth, sex, height_cm, unit_system, training_level, goal',
        )
        .eq('id', userId)
        .maybeSingle();
  }

  Future<bool> hasCurrentProfile() async => (await getCurrentProfile()) != null;

  Future<void> upsertProfile({
    required String displayName,
    required DateTime? dateOfBirth,
    required String? sex,
    required double? heightCm,
    required String unitSystem,
    required String trainingLevel,
    required String goal,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user.');
    }

    await _client.from('users_profiles').upsert({
      'id': userId,
      'display_name': displayName.trim(),
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'sex': sex,
      'height_cm': heightCm,
      'unit_system': unitSystem,
      'training_level': trainingLevel,
      'goal': goal,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
