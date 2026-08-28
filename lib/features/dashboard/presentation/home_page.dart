import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/fitforge_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_shell.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(Supabase.instance.client),
);
final dashboardSnapshotProvider = FutureProvider<DashboardSnapshot>(
  (ref) => ref.read(dashboardRepositoryProvider).loadSnapshot(),
);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(dashboardSnapshotProvider);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: const FitForgeLogo(compact: true),
        actions: [
          IconButton(
            tooltip: 'Progress',
            onPressed: () => context.push('/progress'),
            icon: const Icon(Icons.insights_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (route) async {
              if (route == 'logout') {
                await ref.read(authControllerProvider).signOut();
                if (context.mounted) context.go('/login');
              } else if (context.mounted) {
                context.push(route);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: '/profile', child: Text('Edit profile')),
              PopupMenuItem(value: '/biometrics', child: Text('Body metrics')),
              PopupMenuItem(value: '/foods', child: Text('Food database')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: snapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(dashboardSnapshotProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardSnapshotProvider.future),
          child: _Dashboard(snapshot: data),
        ),
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 700
          ? NavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (index) {
                const routes = [
                  '/home',
                  '/workouts',
                  '/nutrition',
                  '/progress',
                ];
                if (index > 0) context.push(routes[index]);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fitness_center_rounded),
                  label: 'Train',
                ),
                NavigationDestination(
                  icon: Icon(Icons.restaurant_rounded),
                  label: 'Nutrition',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_rounded),
                  label: 'Progress',
                ),
              ],
            )
          : null,
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.snapshot});
  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final profile = snapshot.profile;
    final name = (profile?['display_name'] as String?)?.trim();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(wide ? 48 : 20, 18, wide ? 48 : 20, 40),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Hero(name: name, goal: _goal(profile?['goal'] as String?)),
                    const SizedBox(height: 24),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _Metrics(data: snapshot.latestBiometrics),
                          ),
                          const SizedBox(width: 24),
                          const Expanded(flex: 5, child: _Actions()),
                        ],
                      )
                    else ...[
                      _Metrics(data: snapshot.latestBiometrics),
                      const SizedBox(height: 24),
                      const _Actions(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static String _goal(String? goal) => switch (goal) {
    'muscle_gain' => 'BUILD MUSCLE',
    'fat_loss' => 'LOSE FAT',
    'maintenance' => 'MAINTAIN',
    'performance' => 'PERFORMANCE',
    _ => 'BUILD YOUR BEST',
  };
}

class _Hero extends StatelessWidget {
  const _Hero({required this.name, required this.goal});
  final String? name;
  final String goal;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        colors: [Color(0xFF263719), Color(0xFF121914)],
      ),
      border: Border.all(color: const Color(0xFF3B5423)),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 24,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal,
              style: const TextStyle(
                color: FitForgeColors.lime,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name?.isNotEmpty == true ? 'Ready, $name?' : 'Ready to forge?',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your future strength is built one session at a time.',
              style: TextStyle(color: FitForgeColors.muted),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () => context.push('/workouts'),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start workout'),
        ),
      ],
    ),
  );
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.data});
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Heading(
        title: 'Body snapshot',
        subtitle: 'Your latest recorded metrics',
      ),
      const SizedBox(height: 14),
      if (data == null)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.monitor_weight_outlined,
                  size: 36,
                  color: FitForgeColors.lime,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No measurements yet',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Add your baseline to start tracking progress.',
                  style: TextStyle(color: FitForgeColors.muted),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.push('/biometrics'),
                  child: const Text('Add measurement'),
                ),
              ],
            ),
          ),
        )
      else
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.65,
          children: [
            _Metric(
              icon: Icons.monitor_weight_outlined,
              label: 'Weight',
              value: _number(data!['weight_kg'], ' kg'),
            ),
            _Metric(
              icon: Icons.percent_rounded,
              label: 'Body fat',
              value: _number(data!['body_fat_pct'], '%'),
            ),
            _Metric(
              icon: Icons.fitness_center_rounded,
              label: 'Muscle',
              value: _number(data!['muscle_mass_kg'], ' kg'),
            ),
            _Metric(
              icon: Icons.speed_rounded,
              label: 'BMI',
              value: _number(data!['bmi'], ''),
            ),
          ],
        ),
    ],
  );

  static String _number(dynamic value, String suffix) {
    if (value == null) return '—';
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    return number == null ? '—' : '${number.toStringAsFixed(1)}$suffix';
  }
}

class _Actions extends StatelessWidget {
  const _Actions();
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Heading(title: 'Quick access', subtitle: 'Everything you need today'),
      SizedBox(height: 14),
      _Action(
        icon: Icons.fitness_center_rounded,
        title: 'Training plan',
        subtitle: 'Open today’s session',
        route: '/workouts',
      ),
      SizedBox(height: 10),
      _Action(
        icon: Icons.restaurant_rounded,
        title: 'Nutrition',
        subtitle: 'Track calories and macros',
        route: '/nutrition',
      ),
      SizedBox(height: 10),
      _Action(
        icon: Icons.auto_awesome_rounded,
        title: 'Smart coach',
        subtitle: 'Generate your daily targets',
        route: '/nutrition-coach',
      ),
      SizedBox(height: 10),
      _Action(
        icon: Icons.insights_rounded,
        title: 'Progress',
        subtitle: 'Review performance',
        route: '/progress',
      ),
    ],
  );
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(color: FitForgeColors.muted)),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: FitForgeColors.lime),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: FitForgeColors.muted)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF243119),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: FitForgeColors.lime),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: FitForgeColors.muted),
      ),
      trailing: const Icon(Icons.arrow_forward_rounded),
      onTap: () => context.push(route),
    ),
  );
}
