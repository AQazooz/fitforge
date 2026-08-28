import 'package:flutter/material.dart';

import '../../../app/fitforge_theme.dart';

class DemoPreviewPage extends StatefulWidget {
  const DemoPreviewPage({super.key});

  @override
  State<DemoPreviewPage> createState() => _DemoPreviewPageState();
}

class _DemoPreviewPageState extends State<DemoPreviewPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FitForge demo'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Chip(
                avatar: Icon(Icons.science_outlined, size: 16),
                label: Text('Preview mode'),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 40 : 16,
                  12,
                  wide ? 40 : 16,
                  32,
                ),
                child: _page,
              ),
            ),
          );
          return wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _select,
                      labelType: NavigationRailLabelType.all,
                      destinations: _railDestinations,
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : content;
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _select,
              destinations: _destinations,
            )
          : null,
    );
  }

  List<NavigationDestination> get _destinations => const [
    NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
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
    NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
  ];

  List<NavigationRailDestination> get _railDestinations => const [
    NavigationRailDestination(
      icon: Icon(Icons.grid_view_rounded),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.fitness_center_rounded),
      label: Text('Train'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.restaurant_rounded),
      label: Text('Nutrition'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.insights_rounded),
      label: Text('Progress'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.person_rounded),
      label: Text('Profile'),
    ),
  ];

  Widget get _page => switch (_selectedIndex) {
    0 => const _DemoHome(),
    1 => const _DemoWorkouts(),
    2 => const _DemoNutrition(),
    3 => const _DemoProgress(),
    _ => const _DemoProfile(),
  };

  void _select(int index) => setState(() => _selectedIndex = index);
}

class _DemoHome extends StatelessWidget {
  const _DemoHome();

  @override
  Widget build(BuildContext context) => const _DemoColumn(
    eyebrow: 'BUILD YOUR BEST',
    title: 'Ready, Alex?',
    subtitle: 'Your future strength is built one session at a time.',
    cards: [
      _DemoCard(
        icon: Icons.fitness_center_rounded,
        title: 'Training plan',
        value: 'Push day • 4 exercises',
      ),
      _DemoCard(
        icon: Icons.restaurant_rounded,
        title: 'Nutrition',
        value: '1,840 / 2,400 kcal',
      ),
      _DemoCard(
        icon: Icons.insights_rounded,
        title: 'Progress',
        value: '12 sessions this month',
      ),
    ],
  );
}

class _DemoWorkouts extends StatelessWidget {
  const _DemoWorkouts();
  @override
  Widget build(BuildContext context) => const _DemoColumn(
    eyebrow: 'TRAINING',
    title: 'Your training plans',
    subtitle: 'Stay consistent with a plan built for your week.',
    cards: [
      _DemoCard(
        icon: Icons.bolt_rounded,
        title: 'Forge Strong',
        value: '4 days/week • Today: Push day',
      ),
      _DemoCard(
        icon: Icons.calendar_month_rounded,
        title: 'Next session',
        value: 'Bench press • Rows • Shoulder press',
      ),
    ],
  );
}

class _DemoNutrition extends StatelessWidget {
  const _DemoNutrition();
  @override
  Widget build(BuildContext context) => const _DemoColumn(
    eyebrow: 'FUEL',
    title: 'Fuel your training',
    subtitle: 'Track what supports your performance.',
    cards: [
      _DemoCard(
        icon: Icons.local_fire_department_rounded,
        title: 'Daily summary',
        value: '1,840 / 2,400 kcal • 128g protein',
      ),
      _DemoCard(
        icon: Icons.restaurant_menu_rounded,
        title: 'Today’s food',
        value: 'Greek yogurt • Chicken bowl • Oats',
      ),
    ],
  );
}

class _DemoProgress extends StatelessWidget {
  const _DemoProgress();
  @override
  Widget build(BuildContext context) => const _DemoColumn(
    eyebrow: 'INSIGHTS',
    title: 'Your progress',
    subtitle: 'A clear view of the work you have put in.',
    cards: [
      _DemoCard(
        icon: Icons.check_circle_rounded,
        title: 'Sessions',
        value: '12 completed',
      ),
      _DemoCard(
        icon: Icons.trending_up_rounded,
        title: 'Volume',
        value: '18,420 kg • +14% this month',
      ),
      _DemoCard(
        icon: Icons.emoji_events_rounded,
        title: 'Best lift',
        value: 'Bench press • 82.5 kg',
      ),
    ],
  );
}

class _DemoProfile extends StatelessWidget {
  const _DemoProfile();
  @override
  Widget build(BuildContext context) => const _DemoColumn(
    eyebrow: 'ATHLETE PROFILE',
    title: 'Alex Morgan',
    subtitle: 'Build muscle • Intermediate • Metric units',
    cards: [
      _DemoCard(icon: Icons.height_rounded, title: 'Height', value: '178 cm'),
      _DemoCard(
        icon: Icons.monitor_weight_outlined,
        title: 'Latest weight',
        value: '76.4 kg',
      ),
      _DemoCard(
        icon: Icons.flag_rounded,
        title: 'Goal',
        value: 'Build your strongest self',
      ),
    ],
  );
}

class _DemoColumn extends StatelessWidget {
  const _DemoColumn({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.cards,
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) => ListView(
    shrinkWrap: true,
    children: [
      Text(
        eyebrow,
        style: const TextStyle(
          color: FitForgeColors.lime,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 6),
      Text(subtitle, style: const TextStyle(color: FitForgeColors.muted)),
      const SizedBox(height: 24),
      ...cards,
    ],
  );
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
        value,
        style: const TextStyle(color: FitForgeColors.muted),
      ),
      trailing: const Icon(Icons.arrow_forward_rounded),
    ),
  );
}
