import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/workout_repository.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(Supabase.instance.client),
);

final workoutPlansProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.read(workoutRepositoryProvider);
  var plans = await repo.getPlans();
  if (plans.isEmpty) {
    await repo.ensureStarterPlan();
    plans = await repo.getPlans();
  }
  return plans;
});

class WorkoutsPage extends ConsumerWidget {
  const WorkoutsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(workoutPlansProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Workouts')),
      body: plans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(workoutPlansProvider),
            child: const Text('Retry'),
          ),
        ),
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final plan = items[i];
            return Card(
              child: ListTile(
                title: Text('${plan['name']}'),
                subtitle: Text(
                  '${plan['days_per_week'] ?? 0} days/week\n${plan['description'] ?? ''}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutPlanPage(
                      planId: plan['id'] as String,
                      planName: plan['name'] as String,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class WorkoutPlanPage extends ConsumerWidget {
  const WorkoutPlanPage({
    super.key,
    required this.planId,
    required this.planName,
  });
  final String planId;
  final String planName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.read(workoutRepositoryProvider).getPlanDays(planId);
    return Scaffold(
      appBar: AppBar(title: Text(planName)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return const Center(child: Text('Could not load workout days.'));
          final days = snapshot.data ?? const [];
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: days.length,
            itemBuilder: (_, i) {
              final day = days[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${day['day_number']}')),
                  title: Text('${day['title']}'),
                  subtitle: Text('${day['notes'] ?? ''}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutDayPage(
                        dayId: day['id'] as String,
                        dayTitle: day['title'] as String,
                        planId: planId,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class WorkoutDayPage extends ConsumerWidget {
  const WorkoutDayPage({
    super.key,
    required this.dayId,
    required this.dayTitle,
    required this.planId,
  });
  final String dayId;
  final String dayTitle;
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(dayTitle)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.read(workoutRepositoryProvider).getDayExercises(dayId),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return const Center(child: Text('Could not load exercises.'));
          final exercises = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ...exercises.map((item) {
                final exercise =
                    item['exercises'] as Map<String, dynamic>? ?? {};
                return Card(
                  child: ListTile(
                    title: Text('${exercise['name'] ?? 'Exercise'}'),
                    subtitle: Text(
                      '${item['sets'] ?? 0} sets • ${item['reps_min'] ?? '-'}-${item['reps_max'] ?? '-'} reps • ${item['rest_seconds'] ?? 0}s rest',
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: exercises.isEmpty
                    ? null
                    : () async {
                        final sessionId = await ref
                            .read(workoutRepositoryProvider)
                            .startSession(planId: planId);
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkoutSessionPage(
                              sessionId: sessionId,
                              dayTitle: dayTitle,
                              exercises: exercises,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start workout'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class WorkoutSessionPage extends ConsumerStatefulWidget {
  const WorkoutSessionPage({
    super.key,
    required this.sessionId,
    required this.dayTitle,
    required this.exercises,
  });
  final String sessionId;
  final String dayTitle;
  final List<Map<String, dynamic>> exercises;

  @override
  ConsumerState<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends ConsumerState<WorkoutSessionPage> {
  final Map<String, List<Map<String, TextEditingController>>> _fields = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final item in widget.exercises) {
      final id = item['exercise_id'] as String;
      final count = (item['sets'] as num?)?.toInt() ?? 1;
      _fields[id] = List.generate(
        count,
        (_) => {
          'weight': TextEditingController(),
          'reps': TextEditingController(),
          'rir': TextEditingController(),
        },
      );
    }
  }

  @override
  void dispose() {
    for (final sets in _fields.values) {
      for (final set in sets) {
        for (final controller in set.values) {
          controller.dispose();
        }
      }
    }
    super.dispose();
  }

  Future<void> _complete() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(workoutRepositoryProvider);
      for (final item in widget.exercises) {
        final id = item['exercise_id'] as String;
        final sets = _fields[id] ?? const [];
        for (var i = 0; i < sets.length; i++) {
          final set = sets[i];
          final reps = int.tryParse(set['reps']!.text);
          final weight = double.tryParse(set['weight']!.text);
          final rir = double.tryParse(set['rir']!.text);
          if (reps == null && weight == null && rir == null) continue;
          await repo.logSet(
            workoutLogId: widget.sessionId,
            exerciseId: id,
            setNumber: i + 1,
            reps: reps,
            weightKg: weight,
            rir: rir,
          );
        }
      }
      await repo.completeSession(widget.sessionId);
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save workout: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.dayTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...widget.exercises.map((item) {
            final exercise = item['exercises'] as Map<String, dynamic>? ?? {};
            final sets = _fields[item['exercise_id'] as String] ?? const [];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${exercise['name']}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...sets.asMap().entries.map((entry) {
                      final f = entry.value;
                      return Row(
                        children: [
                          SizedBox(width: 28, child: Text('${entry.key + 1}')),
                          Expanded(
                            child: TextField(
                              controller: f['weight'],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'kg',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: f['reps'],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'reps',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: f['rir'],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'RIR',
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
          FilledButton(
            onPressed: _saving ? null : _complete,
            child: _saving
                ? const CircularProgressIndicator()
                : const Text('Complete workout'),
          ),
        ],
      ),
    );
  }
}
