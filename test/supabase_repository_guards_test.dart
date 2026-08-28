import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fitforge/features/biometrics/data/biometrics_repository.dart';
import 'package:fitforge/features/dashboard/data/dashboard_repository.dart';
import 'package:fitforge/features/nutrition/data/nutrition_repository.dart';
import 'package:fitforge/features/workouts/data/progress_repository.dart';
import 'package:fitforge/features/workouts/data/workout_repository.dart';

void main() {
  final client = SupabaseClient('https://example.supabase.co', 'test-key');

  Future<void> expectUnauthenticated(Future<Object?> Function() operation) async {
    await expectLater(operation(), throwsA(isA<StateError>()));
  }

  test('workout repository blocks user-owned operations without a session', () async {
    final repository = WorkoutRepository(client);

    await expectUnauthenticated(repository.getPlans);
    await expectUnauthenticated(() => repository.startSession());
    await expectUnauthenticated(
      () => repository.completeSession('workout-log-id'),
    );
  });

  test('nutrition repository blocks RLS-scoped operations without a session', () async {
    final repository = NutritionRepository(client);

    await expectUnauthenticated(() => repository.loadDay(DateTime(2026, 8, 28)));
    await expectUnauthenticated(repository.loadNutritionContext);
    await expectUnauthenticated(
      () => repository.saveTarget(
        effectiveFrom: DateTime(2026, 8, 28),
        calories: 2400,
        proteinG: 160,
        carbsG: 250,
        fatG: 70,
        fiberG: 30,
      ),
    );
    await expectUnauthenticated(
      () => repository.addFood(
        consumedAt: DateTime(2026, 8, 28, 12),
        foodName: 'Chicken bowl',
        mealType: 'lunch',
        calories: 600,
        proteinG: 45,
        carbsG: 55,
        fatG: 18,
        servingSize: '1 bowl',
      ),
    );
    await expectUnauthenticated(() => repository.deleteFood('food-id'));
  });

  test('biometrics, dashboard, and progress repositories require a session', () async {
    await expectUnauthenticated(BiometricsRepository(client).getHistory);
    await expectUnauthenticated(
      () => BiometricsRepository(client).addMeasurement(
        measuredAt: DateTime(2026, 8, 28),
        weightKg: 80,
      ),
    );
    await expectUnauthenticated(DashboardRepository(client).loadSnapshot);
    await expectUnauthenticated(ProgressRepository(client).getHistory);
    await expectUnauthenticated(ProgressRepository(client).getExerciseProgress);
  });

  test('nutrition day preserves an absent target and computes empty totals', () {
    const day = NutritionDay(target: null, logs: []);

    expect(day.target, isNull);
    expect(day.calories, 0);
    expect(day.protein, 0);
    expect(day.carbs, 0);
    expect(day.fat, 0);
  });
}
