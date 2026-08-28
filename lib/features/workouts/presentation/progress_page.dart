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

  @override
  void initState() {
    super.initState();
    _repository = ProgressRepository(Supabase.instance.client);
    _historyFuture = _repository.getHistory();
  }

  void _refresh() {
    setState(() => _historyFuture = _repository.getHistory());
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

          if (history.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.insights_outlined, size: 64),
                  SizedBox(height: 16),
                  Center(
                    child: Text('Complete your first workout to see progress.'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
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
                        value:
                            '${summary.bestEstimated1RmKg.toStringAsFixed(1)} kg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Workout history',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
