import 'package:supabase_flutter/supabase_flutter.dart';

class BiometricsRepository {
  BiometricsRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  Future<List<Map<String, dynamic>>> getHistory({int limit = 30}) async {
    final data = await _client
        .from('athlete_biometrics')
        .select('id, measured_at, weight_kg, body_fat_pct, muscle_mass_kg, bmi, waist_cm, notes')
        .eq('user_id', _userId)
        .order('measured_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addMeasurement({
    required DateTime measuredAt,
    required double weightKg,
    double? bodyFatPct,
    double? muscleMassKg,
    double? waistCm,
    String? notes,
  }) async {
    final profile = await _client
        .from('users_profiles')
        .select('height_cm')
        .eq('id', _userId)
        .single();
    final heightCm = (profile['height_cm'] as num?)?.toDouble();
    final bmi = heightCm == null || heightCm <= 0 ? null : weightKg / ((heightCm / 100) * (heightCm / 100));

    await _client.from('athlete_biometrics').insert({
      'user_id': _userId,
      'measured_at': measuredAt.toUtc().toIso8601String(),
      'weight_kg': weightKg,
      'body_fat_pct': bodyFatPct,
      'muscle_mass_kg': muscleMassKg,
      'bmi': bmi,
      'waist_cm': waistCm,
      'notes': notes?.trim(),
    });
  }
}
