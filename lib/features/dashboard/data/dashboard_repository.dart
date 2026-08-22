import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.profile,
    required this.latestBiometrics,
  });

  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? latestBiometrics;
}

class DashboardRepository {
  DashboardRepository(this._client);

  final SupabaseClient _client;

  Future<DashboardSnapshot> loadSnapshot() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user.');
    }

    final profile = await _client
        .from('users_profiles')
        .select('display_name, height_cm, unit_system, training_level, goal')
        .eq('id', userId)
        .maybeSingle();

    final biometrics = await _client
        .from('athlete_biometrics')
        .select('measured_at, weight_kg, body_fat_pct, muscle_mass_kg, bmi, waist_cm')
        .eq('user_id', userId)
        .order('measured_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return DashboardSnapshot(
      profile: profile,
      latestBiometrics: biometrics,
    );
  }
}
