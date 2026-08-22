import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutRepository {
  WorkoutRepository(this._client);

  final SupabaseClient _client;

  Future<String> ensureStarterPlan() async {
    final result = await _client.rpc('create_starter_workout_plan');
    return result as String;
  }

  Future<List<Map<String, dynamic>>> getPlans() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('No authenticated user.');

    return List<Map<String, dynamic>>.from(
      await _client
          .from('workout_plans')
          .select('id, name, description, goal, days_per_week, is_active')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false),
    );
  }

  Future<List<Map<String, dynamic>>> getPlanDays(String planId) async {
    return List<Map<String, dynamic>>.from(
      await _client
          .from('workout_plan_days')
          .select('id, day_number, title, notes')
          .eq('plan_id', planId)
          .order('day_number'),
    );
  }

  Future<List<Map<String, dynamic>>> getDayExercises(String dayId) async {
    return List<Map<String, dynamic>>.from(
      await _client
          .from('workout_plan_exercises')
          .select('id, exercise_id, sort_order, sets, reps_min, reps_max, rest_seconds, target_rir, notes, exercises(id, name, muscle_group, equipment)')
          .eq('plan_day_id', dayId)
          .order('sort_order'),
    );
  }

  Future<String> startSession({String? planId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('No authenticated user.');

    final row = await _client
        .from('workout_logs')
        .insert({'user_id': userId, 'plan_id': planId})
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> logSet({
    required String workoutLogId,
    required String exerciseId,
    required int setNumber,
    int? reps,
    double? weightKg,
    double? rir,
    int? durationSeconds,
    String? notes,
  }) async {
    await _client.from('workout_log_sets').insert({
      'workout_log_id': workoutLogId,
      'exercise_id': exerciseId,
      'set_number': setNumber,
      'reps': reps,
      'weight_kg': weightKg,
      'rir': rir,
      'duration_seconds': durationSeconds,
      'notes': notes,
    });
  }

  Future<void> completeSession(String workoutLogId, {String? notes}) async {
    await _client
        .from('workout_logs')
        .update({
          'completed_at': DateTime.now().toUtc().toIso8601String(),
          'notes': notes,
        })
        .eq('id', workoutLogId);
  }
}
