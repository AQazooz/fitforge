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
      await _client.from('workout_plans').select('id, name, description, goal, days_per_week, is_active').eq('user_id', userId).eq('is_active', true).order('created_at', ascending: false),
    );
  }

  Future<List<Map<String, dynamic>>> getPlanDays(String planId) async {
    return List<Map<String, dynamic>>.from(
      await _client.from('workout_plan_days').select('id, day_number, title, notes').eq('plan_id', planId).order('day_number'),
    );
  }

  Future<List<Map<String, dynamic>>> getDayExercises(String dayId) async {
    return List<Map<String, dynamic>>.from(
      await _client.from('workout_plan_exercises').select('id, exercise_id, sort_order, sets, reps_min, reps_max, rest_seconds, target_rir, notes, exercises(id, name, muscle_group, equipment)').eq('plan_day_id', dayId).order('sort_order'),
    );
  }

  Future<String> startSession({String? planId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('No authenticated user.');

    final row = await _client.from('workout_logs').insert({'user_id': userId, 'plan_id': planId}).select('id').single();
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
    if (setNumber < 1) throw ArgumentError.value(setNumber, 'setNumber', 'must be at least 1');
    if (reps != null && (reps < 1 || reps > 1000)) throw ArgumentError.value(reps, 'reps', 'must be between 1 and 1000');
    if (weightKg != null && (weightKg < 0 || weightKg > 1000)) throw ArgumentError.value(weightKg, 'weightKg', 'must be between 0 and 1000 kg');
    if (rir != null && (rir < 0 || rir > 10)) throw ArgumentError.value(rir, 'rir', 'must be between 0 and 10');
    if (durationSeconds != null && (durationSeconds < 0 || durationSeconds > 86400)) throw ArgumentError.value(durationSeconds, 'durationSeconds', 'must be between 0 and 86400');
    if (reps == null && weightKg == null && rir == null && durationSeconds == null && (notes == null || notes.trim().isEmpty)) {
      throw ArgumentError('A workout set must contain at least one logged value.');
    }

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
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('No authenticated user.');

    final existing = await _client.from('workout_logs').select('id, completed_at').eq('id', workoutLogId).eq('user_id', userId).maybeSingle();
    if (existing == null) throw StateError('Workout session not found.');
    if (existing['completed_at'] != null) throw StateError('Workout session is already completed.');

    final sets = await _client.from('workout_log_sets').select('id').eq('workout_log_id', workoutLogId).limit(1);
    if ((sets as List).isEmpty) throw StateError('Log at least one set before completing the workout.');

    await _client.from('workout_logs').update({'completed_at': DateTime.now().toUtc().toIso8601String(), 'notes': notes}).eq('id', workoutLogId).eq('user_id', userId);
  }
}
