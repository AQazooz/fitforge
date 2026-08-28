import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) => DashboardRepository(Supabase.instance.client));
final dashboardSnapshotProvider = FutureProvider<DashboardSnapshot>((ref) => ref.read(dashboardRepositoryProvider).loadSnapshot());

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(dashboardSnapshotProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('FitForge'),
        actions: [
          IconButton(onPressed: () => context.push('/workouts'), icon: const Icon(Icons.fitness_center)),
          IconButton(onPressed: () => context.push('/progress'), icon: const Icon(Icons.insights)),
          IconButton(onPressed: () => context.push('/nutrition'), icon: const Icon(Icons.restaurant)),
          IconButton(onPressed: () => context.push('/nutrition-coach'), icon: const Icon(Icons.auto_awesome)),
          IconButton(onPressed: () => context.push('/biometrics'), icon: const Icon(Icons.monitor_weight_outlined)),
          IconButton(tooltip: 'Sign out', onPressed: () async { await ref.read(authControllerProvider).signOut(); if (context.mounted) context.go('/login'); }, icon: const Icon(Icons.logout)),
        ],
      ),
      body: snapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: FilledButton(onPressed: () => ref.invalidate(dashboardSnapshotProvider), child: const Text('Retry'))),
        data: (data) => RefreshIndicator(onRefresh: () => ref.refresh(dashboardSnapshotProvider.future), child: _DashboardContent(snapshot: data)),
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Text(name?.isNotEmpty == true ? 'Welcome back, $name' : 'Welcome back', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(_formatGoal(profile?['goal'] as String?), style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        Text('Your body metrics', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (biometrics == null)
          const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No body measurement yet. Add your first measurement to start tracking progress.')))
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _MetricCard(label: 'Weight', value: _number(biometrics['weight_kg'], ' kg')),
              _MetricCard(label: 'Body fat', value: _number(biometrics['body_fat_pct'], '%')),
              _MetricCard(label: 'Muscle mass', value: _number(biometrics['muscle_mass_kg'], ' kg')),
              _MetricCard(label: 'BMI', value: _number(biometrics['bmi'], '')),
            ],
          ),
        const SizedBox(height: 28),
        Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _ActionCard(icon: Icons.fitness_center, title: 'Start workout', subtitle: 'Open your training plan.', onTap: () => context.push('/workouts')),
        const SizedBox(height: 12),
        _ActionCard(icon: Icons.restaurant, title: 'Log nutrition', subtitle: 'Track calories and macros for today.', onTap: () => context.push('/nutrition')),
        const SizedBox(height: 12),
        _ActionCard(icon: Icons.auto_awesome, title: 'Nutrition Coach', subtitle: 'Generate a starting calorie and macro target.', onTap: () => context.push('/nutrition-coach')),
        const SizedBox(height: 12),
        _ActionCard(icon: Icons.search, title: 'Food database', subtitle: 'Search foods and add them in servings.', onTap: () => context.push('/foods')),
        const SizedBox(height: 12),
        _ActionCard(icon: Icons.monitor_weight_outlined, title: 'Body metrics', subtitle: 'Log weight, body fat, muscle, and waist.', onTap: () => context.push('/biometrics')),
        const SizedBox(height: 12),
        _ActionCard(icon: Icons.insights, title: 'View progress', subtitle: 'Review workout history and performance.', onTap: () => context.push('/progress')),
      ],
    );
  }

  static String _number(dynamic value, String suffix) {
    if (value == null) return '—';
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    return number == null ? '—' : '${number.toStringAsFixed(1)}$suffix';
  }

  static String _formatGoal(String? goal) {
    switch (goal) {
      case 'muscle_gain': return 'Build muscle';
      case 'fat_loss': return 'Lose fat';
      case 'maintenance': return 'Maintain your current shape';
      case 'performance': return 'Improve performance';
      default: return 'Let’s build your fitness journey.';
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(label), const SizedBox(height: 6), Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))])));
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right), onTap: onTap));
}
