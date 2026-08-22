import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(Supabase.instance.client);
});

final dashboardSnapshotProvider = FutureProvider<DashboardSnapshot>((ref) {
  return ref.read(dashboardRepositoryProvider).loadSnapshot();
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(dashboardSnapshotProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FitForge'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authControllerProvider).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: snapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: 'Could not load your dashboard.',
          onRetry: () => ref.invalidate(dashboardSnapshotProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardSnapshotProvider.future),
          child: _DashboardContent(snapshot: data),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final profile = snapshot.profile;
    final biometrics = snapshot.latestBiometrics;
    final name = (profile?['display_name'] as String?)?.trim();
    final goal = _formatGoal(profile?['goal'] as String?);
    final weight = biometrics?['weight_kg'];
    final bodyFat = biometrics?['body_fat_pct'];
    final muscle = biometrics?['muscle_mass_kg'];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          name?.isNotEmpty == true ? 'Welcome back, $name' : 'Welcome back',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(goal, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        Text('Your body metrics', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (biometrics == null)
          _EmptyMetricsCard()
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _MetricCard(label: 'Weight', value: _number(weight, ' kg')),
              _MetricCard(label: 'Body fat', value: _number(bodyFat, '%')),
              _MetricCard(label: 'Muscle mass', value: _number(muscle, ' kg')),
              _MetricCard(label: 'BMI', value: _number(biometrics['bmi'], '')),
            ],
          ),
        const SizedBox(height: 28),
        Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.fitness_center,
          title: 'Start workout',
          subtitle: 'Training session tracking is coming next.',
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.restaurant,
          title: 'Log nutrition',
          subtitle: 'Calories and macros will be available here.',
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.insights,
          title: 'View progress',
          subtitle: 'Track your body and workout progress over time.',
        ),
      ],
    );
  }

  static String _number(dynamic value, String suffix) {
    if (value == null) return '—';
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    if (number == null) return '—';
    return '${number.toStringAsFixed(1)}$suffix';
  }

  static String _formatGoal(String? goal) {
    switch (goal) {
      case 'muscle_gain':
        return 'Build muscle';
      case 'fat_loss':
        return 'Lose fat';
      case 'maintenance':
        return 'Maintain your current shape';
      case 'performance':
        return 'Improve performance';
      default:
        return 'Let’s build your fitness journey.';
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMetricsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.monitor_weight_outlined, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'No body measurement yet. Add your first measurement to start tracking progress.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
