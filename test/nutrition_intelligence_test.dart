import 'package:flutter_test/flutter_test.dart';

import 'package:fitforge/features/nutrition/data/nutrition_intelligence.dart';

void main() {
  test('nutrition recommendation uses body-fat method when available', () {
    final result = NutritionIntelligence.calculate(
      profile: {
        'height_cm': 170,
        'date_of_birth': '1995-01-01',
        'sex': 'male',
        'training_level': 'intermediate',
        'goal': 'muscle_gain',
      },
      biometrics: {
        'weight_kg': 70,
        'body_fat_pct': 15,
      },
    );

    expect(result.calories, greaterThan(2000));
    expect(result.proteinG, closeTo(112, 0.01));
    expect(result.fatG, greaterThan(0));
    expect(result.carbsG, greaterThan(0));
    expect(result.method, contains('Katch-McArdle'));
  });

  test('nutrition recommendation fails without height and weight', () {
    expect(
      () => NutritionIntelligence.calculate(
        profile: {'height_cm': null, 'goal': 'maintenance'},
        biometrics: {'weight_kg': null},
      ),
      throwsStateError,
    );
  });
}
