import 'package:supabase_flutter/supabase_flutter.dart';

class NutritionDay {
  const NutritionDay({required this.target, required this.logs});

  final Map<String, dynamic>? target;
  final List<Map<String, dynamic>> logs;

  int get calories => logs.fold<int>(0, (sum, row) => sum + ((row['calories'] as num?)?.toInt() ?? 0));
  double get protein => logs.fold<double>(0, (sum, row) => sum + ((row['protein_g'] as num?)?.toDouble() ?? 0));
  double get carbs => logs.fold<double>(0, (sum, row) => sum + ((row['carbs_g'] as num?)?.toDouble() ?? 0));
  double get fat => logs.fold<double>(0, (sum, row) => sum + ((row['fat_g'] as num?)?.toDouble() ?? 0));

  num? get targetCalories => target?['calories'] as num?;
  num? get targetProtein => target?['protein_g'] as num?;
  num? get targetCarbs => target?['carbs_g'] as num?;
  num? get targetFat => target?['fat_g'] as num?;
  num? get targetFiber => target?['fiber_g'] as num?;
}

class NutritionRepository {
  NutritionRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  Future<NutritionDay> loadDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final target = await _client
        .from('nutrition_targets')
        .select('id, effective_from, calories, protein_g, carbs_g, fat_g, fiber_g')
        .eq('user_id', _userId)
        .lte('effective_from', _dateOnly(start))
        .order('effective_from', ascending: false)
        .limit(1)
        .maybeSingle();

    final logs = await _client
        .from('nutrition_logs')
        .select('id, consumed_at, meal_type, food_name, calories, protein_g, carbs_g, fat_g, serving_size')
        .eq('user_id', _userId)
        .gte('consumed_at', start.toUtc().toIso8601String())
        .lt('consumed_at', end.toUtc().toIso8601String())
        .order('consumed_at', ascending: false);

    return NutritionDay(target: target, logs: List<Map<String, dynamic>>.from(logs));
  }

  Future<Map<String, dynamic>> loadNutritionContext() async {
    final profile = await _client
        .from('users_profiles')
        .select('date_of_birth, sex, height_cm, training_level, goal')
        .eq('id', _userId)
        .single();

    final biometrics = await _client
        .from('athlete_biometrics')
        .select('weight_kg, body_fat_pct, measured_at')
        .eq('user_id', _userId)
        .order('measured_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return {'profile': Map<String, dynamic>.from(profile), 'biometrics': biometrics};
  }

  Future<void> saveTarget({
    required DateTime effectiveFrom,
    required int calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required double fiberG,
  }) async {
    await _client.from('nutrition_targets').upsert(
      {
        'user_id': _userId,
        'effective_from': _dateOnly(effectiveFrom),
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'fiber_g': fiberG,
      },
      onConflict: 'user_id,effective_from',
    );
  }

  Future<void> addFood({
    required DateTime consumedAt,
    required String foodName,
    required String mealType,
    required int calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required String servingSize,
  }) async {
    await _client.from('nutrition_logs').insert({
      'user_id': _userId,
      'consumed_at': consumedAt.toUtc().toIso8601String(),
      'meal_type': mealType,
      'food_name': foodName.trim(),
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'serving_size': servingSize.trim(),
    });
  }

  Future<void> deleteFood(String id) async {
    await _client.from('nutrition_logs').delete().eq('id', id).eq('user_id', _userId);
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
