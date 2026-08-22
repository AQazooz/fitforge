import 'package:flutter_test/flutter_test.dart';

import 'package:fitforge/features/workouts/data/progress_repository.dart';

void main() {
  test('progress summary aggregates sessions, sets, volume and estimated 1RM', () {
    final summary = ProgressSummary.fromHistory([
      {
        'completed_at': '2026-08-22T08:00:00Z',
        'workout_log_sets': [
          {'reps': 10, 'weight_kg': 50},
          {'reps': 8, 'weight_kg': 60},
        ],
      },
      {
        'completed_at': null,
        'workout_log_sets': [
          {'reps': 12, 'weight_kg': 40},
        ],
      },
    ]);

    expect(summary.completedSessions, 1);
    expect(summary.totalSets, 3);
    expect(summary.totalVolumeKg, closeTo(1460, 0.01));
    expect(summary.bestEstimated1RmKg, closeTo(76, 0.01));
  });
}
