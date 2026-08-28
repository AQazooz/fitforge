import 'dart:math' as math;

class NutritionRecommendation {
  const NutritionRecommendation({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.method,
  });

  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final String method;
}

class NutritionIntelligence {
  static NutritionRecommendation calculate({
    required Map<String, dynamic> profile,
    required Map<String, dynamic>? biometrics,
  }) {
    final height = _number(profile['height_cm']);
    final weight = _number(biometrics?['weight_kg']);
    final sex = profile['sex'] as String?;
    final goal = profile['goal'] as String? ?? 'maintenance';
    final level = profile['training_level'] as String? ?? 'beginner';
    final dob = _date(profile['date_of_birth']);
    final bodyFat = _number(biometrics?['body_fat_pct']);

    if (height == null || weight == null || height <= 0 || weight <= 0) {
      throw StateError('Add height and a current body weight first.');
    }

    final age = dob == null ? null : _ageAt(dob, DateTime.now());
    double bmr;
    String method;

    if (bodyFat != null && bodyFat > 5 && bodyFat < 60) {
      final leanMass = weight * (1 - bodyFat / 100);
      bmr = 370 + (21.6 * leanMass);
      method = 'Katch-McArdle estimate using body-fat data.';
    } else if (age != null && age > 0 && sex != null) {
      bmr = 10 * weight + 6.25 * height - 5 * age + (sex == 'male' ? 5 : -161);
      method = 'Mifflin-St Jeor estimate using profile data.';
    } else {
      bmr = 22 * weight;
      method =
          'Fallback estimate; add sex and date of birth for personalization.';
    }

    final activity = switch (level) {
      'advanced' => 1.6,
      'intermediate' => 1.5,
      _ => 1.4,
    };

    var calories = bmr * activity;
    calories *= switch (goal) {
      'muscle_gain' => 1.10,
      'fat_loss' => 0.85,
      'performance' => 1.05,
      _ => 1.0,
    };

    final safeCalories = calories.round().clamp(1200, 5000);
    final protein = weight * (goal == 'fat_loss' ? 1.8 : 1.6);
    final fat = (safeCalories * 0.25) / 9;
    final remaining = math.max(0, safeCalories - (protein * 4) - (fat * 9));
    final carbs = remaining / 4;
    final fiber = math.max(20, safeCalories / 1000 * 14).toDouble();

    return NutritionRecommendation(
      calories: safeCalories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      fiberG: fiber,
      method: method,
    );
  }

  static double? _number(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse('$value');

  static int _ageAt(DateTime birthDate, DateTime today) {
    var age = today.year - birthDate.year;
    final birthdayPassed =
        today.month > birthDate.month ||
        (today.month == birthDate.month && today.day >= birthDate.day);
    if (!birthdayPassed) age--;
    return age;
  }
}
