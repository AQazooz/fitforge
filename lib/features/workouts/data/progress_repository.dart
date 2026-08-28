import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressRepository {
  ProgressRepository(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getHistory({int limit = 20}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('No authenticated user.');

    final data = await _client
        .from('workout_logs')
        .select(
          'id, started_at, completed_at, notes, workout_plans(name), workout_log_sets(set_number, reps, weight_kg, rir, exercise_id, exercises(name))',
        )
        .eq('user_id', userId)
        .order('started_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getExerciseProgress({
    int limit = 12,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('No authenticated user.');

    final data = await _client
        .from('workout_log_sets')
        .select(
          'exercise_id, reps, weight_kg, rir, workout_logs!inner(user_id, completed_at), exercises(name)',
        )
        .eq('workout_logs.user_id', userId)
        .order(
          'started_at',
          referencedTable: 'workout_logs',
          ascending: false,
        )
        .limit(limit * 20);

    return List<Map<String, dynamic>>.from(data);
  }
}

class ProgressSummary {
  const ProgressSummary({
    required this.completedSessions,
    required this.totalSets,
    required this.totalVolumeKg,
    required this.bestEstimated1RmKg,
  });

  final int completedSessions;
  final int totalSets;
  final double totalVolumeKg;
  final double bestEstimated1RmKg;

  factory ProgressSummary.fromHistory(List<Map<String, dynamic>> history) {
    var sessions = 0;
    var sets = 0;
    var volume = 0.0;
    var best1Rm = 0.0;

    for (final session in history) {
      if (session['completed_at'] != null) sessions++;
      final rawSets = session['workout_log_sets'];
      if (rawSets is! List) continue;
      for (final raw in rawSets) {
        if (raw is! Map<String, dynamic>) continue;
        final reps = (raw['reps'] as num?)?.toDouble();
        final weight = (raw['weight_kg'] as num?)?.toDouble();
        if (reps == null || reps <= 0) continue;
        sets++;
        if (weight != null && weight > 0) {
          volume += weight * reps;
          final estimated1Rm = reps == 1 ? weight : weight * (1 + reps / 30);
          if (estimated1Rm > best1Rm) best1Rm = estimated1Rm;
        }
      }
    }

    return ProgressSummary(
      completedSessions: sessions,
      totalSets: sets,
      totalVolumeKg: volume,
      bestEstimated1RmKg: best1Rm,
    );
  }
}
