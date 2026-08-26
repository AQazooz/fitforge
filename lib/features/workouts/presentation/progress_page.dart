import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/progress_repository.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  late final ProgressRepository _repository;
  late Future<List<Map<String, dynamic>>> _historyFuture;
  late Future<List<Map<String, dynamic>>> _exerciseFuture;

  @override
  void initState() {
    super.initState();
    _repository = ProgressRepository(Supabase.instance.client);
    _refreshFutures();
  }

  void _refreshFutures() {
    _historyFuture = _repository.getHistory();
    _exerciseFuture = _repository.getExerciseProgress();
  }

  Future<void> _refresh() async {
    setState(_refreshFutures);
    await Future.wait([_historyFuture, _exerciseFuture]);
  }

  String _formatDate(String? value) {
    if (value == null) return '-';
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            );
          }

          final history = snapshot.data ?? const <Map<String, dynamic>>[];
          final summary = ProgressSummary.fromHistory(history);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Sessions',
                        value: '${summary.completedSessions}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'Sets',
                        value: '${summary.totalSets}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Volume',
                        value: '${summary.totalVolumeKg.toStringAsFixed(0)} kg',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'Best est. 1RM',
                        value: '${summary.bestEstimated1RmKg.toStringAsFixed(1)} kg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Exercise highlights',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _exerciseFuture,
                  builder: (context, exerciseSnapshot) {
                    if (exerciseSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (exerciseSnapshot.hasError) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Exercise performance is temporarily unavailable.',
                          ),
                        ),
                      );
                    }

                    final highlights = _buildHighlights(
                      exerciseSnapshot.data ?? const [],
                    );
                    if (highlights.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Complete weighted sets to see exercise progress.',
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: highlights
                          .map(
                            (item) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.trending_up),
                                title: Text(item.name),
                                subtitle: Text('${item.sets} logged sets'),
                                trailing: Text(
                                  '${item.best1Rm.toStringAsFixed(1)} kg\n1RM',
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Workout history',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (history.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Complete your first workout to see progress.',
                      ),
                    ),
                  )
                else
                  ...history.map((session) {
                    final plan = session['workout_plans'];
                    final planName = plan is Map<String, dynamic>
                        ? plan['name'] as String?
                        : null;
                    final sets = session['workout_log_sets'];
                    final setCount = sets is List ? sets.length : 0;
                    final completed = session['completed_at'] != null;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          completed ? Icons.check_circle : Icons.timelapse,
                        ),
                        title: Text(planName ?? 'Workout session'),
                        subtitle: Text(
                          '${_formatDate(session['started_at'] as String?)} • $setCount sets',
                        ),
                        trailing: completed
                            ? const Text('Done')
                            : const Text('Open'),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  List<_ExerciseHighlight> _buildHighlights(
    List<Map<String, dynamic>> rows,
  ) {
    final byExercise = <String, _ExerciseAccumulator>{};

    for (final row in rows) {
      if (row['workout_logs'] is! Map<String, dynamic>) continue;
      final log = row['workout_logs'] as Map<String, dynamic>;
      if (log['completed_at'] == null) continue;

      final exercise = row['exercises'] is Map<String, dynamic>
          ? row['exercises'] as Map<String, dynamic>
          : const <String, dynamic>{};
      final id = '${row['exercise_id']}';
      final name = '${exercise['name'] ?? 'Exercise'}';
      final reps = (row['reps'] as num?)?.toDouble();
      final weight = (row['weight_kg'] as num?)?.toDouble();
      if (reps == null || reps <= 0 || weight == null || weight <= 0) continue;

      final oneRm = reps == 1 ? weight : weight * (1 + reps / 30);
      final current = byExercise.putIfAbsent(
        id,
        () => _ExerciseAccumulator(name),
      );
      current.sets++;
      if (oneRm > current.best1Rm) current.best1Rm = oneRm;
    }

    return byExercise.values
        .map((v) => _ExerciseHighlight(v.name, v.sets, v.best1Rm))
        .toList()
      ..sort((a, b) => b.best1Rm.compareTo(a.best1Rm));
  }
}

class _ExerciseAccumulator {
  _ExerciseAccumulator(this.name);

  final String name;
  int sets = 0;
  double best1Rm = 0;
}

class _ExerciseHighlight {
  const _ExerciseHighlight(this.name, this.sets, this.best1Rm);

  final String name;
  final int sets;
  final double best1Rm;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
