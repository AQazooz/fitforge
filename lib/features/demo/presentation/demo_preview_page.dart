import 'package:flutter/material.dart';

import '../../../app/fitforge_theme.dart';

class DemoPreviewPage extends StatefulWidget {
  const DemoPreviewPage({super.key});

  @override
  State<DemoPreviewPage> createState() => _DemoPreviewPageState();
}

class _DemoPreviewPageState extends State<DemoPreviewPage> {
  int _selectedIndex = 0;
  bool _arabic = true;

  DemoStrings get _strings => DemoStrings(_arabic);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_strings.demoTitle),
        actions: [
          Semantics(
            button: true,
            label: _strings.languageTooltip,
            child: IconButton(
              tooltip: _strings.languageTooltip,
              onPressed: () => setState(() => _arabic = !_arabic),
              icon: const Icon(Icons.language_rounded),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Center(
              child: Semantics(
                label: _strings.previewMode,
                child: Chip(
                  avatar: const Icon(Icons.science_outlined, size: 16),
                  label: Text(_strings.previewMode),
                ),
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
                child: Directionality(
                  textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
                  child: _page,
                ),
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
          ? Directionality(
              textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _select,
                destinations: _destinations,
              ),
            )
          : null,
    );
  }

  List<NavigationDestination> get _destinations => [
    NavigationDestination(icon: const Icon(Icons.grid_view_rounded), label: _strings.home),
    NavigationDestination(
      icon: const Icon(Icons.fitness_center_rounded),
      label: _strings.train,
    ),
    NavigationDestination(
      icon: const Icon(Icons.restaurant_rounded),
      label: _strings.nutrition,
    ),
    NavigationDestination(
      icon: const Icon(Icons.insights_rounded),
      label: _strings.progress,
    ),
    NavigationDestination(icon: const Icon(Icons.person_rounded), label: _strings.profile),
  ];

  List<NavigationRailDestination> get _railDestinations => [
    NavigationRailDestination(
      icon: const Icon(Icons.grid_view_rounded),
      label: Text(_strings.home),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.fitness_center_rounded),
      label: Text(_strings.train),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.restaurant_rounded),
      label: Text(_strings.nutrition),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.insights_rounded),
      label: Text(_strings.progress),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.person_rounded),
      label: Text(_strings.profile),
    ),
  ];

  Widget get _page => switch (_selectedIndex) {
    0 => _DemoHome(strings: _strings),
    1 => _DemoWorkouts(strings: _strings),
    2 => _DemoNutrition(strings: _strings),
    3 => _DemoProgress(strings: _strings),
    _ => _DemoProfile(strings: _strings),
  };

  void _select(int index) => setState(() => _selectedIndex = index);
}

class DemoStrings {
  const DemoStrings(this.arabic);
  final bool arabic;

  String get demoTitle => arabic ? 'معاينة FitForge' : 'FitForge demo';
  String get previewMode => arabic ? 'وضع المعاينة' : 'Preview mode';
  String get languageTooltip => arabic ? 'التبديل إلى الإنجليزية' : 'التبديل إلى العربية';
  String get home => arabic ? 'الرئيسية' : 'Home';
  String get train => arabic ? 'التدريب' : 'Train';
  String get nutrition => arabic ? 'التغذية' : 'Nutrition';
  String get progress => arabic ? 'التقدم' : 'Progress';
  String get profile => arabic ? 'الملف الشخصي' : 'Profile';
}

class _DemoHome extends StatelessWidget {
  const _DemoHome({required this.strings});
  final DemoStrings strings;

  @override
  Widget build(BuildContext context) => _DemoColumn(
    eyebrow: strings.arabic ? 'ابنِ أفضل نسخة منك' : 'BUILD YOUR BEST',
    title: strings.arabic ? 'مستعد يا أليكس؟' : 'Ready, Alex?',
    subtitle: strings.arabic ? 'قوتك القادمة تُبنى في كل جلسة.' : 'Your future strength is built one session at a time.',
    cards: [
      const _DemoCard(
        icon: Icons.fitness_center_rounded,
        title: 'Training plan',
        value: 'Push day • 4 exercises',
      ),
      const _DemoCard(
        icon: Icons.restaurant_rounded,
        title: 'Nutrition',
        value: '1,840 / 2,400 kcal',
      ),
      const _DemoCard(
        icon: Icons.insights_rounded,
        title: 'Progress',
        value: '12 sessions this month',
      ),
    ],
  );
}

class _DemoWorkouts extends StatelessWidget {
  const _DemoWorkouts({required this.strings});
  final DemoStrings strings;
  @override
  Widget build(BuildContext context) => _DemoColumn(
    eyebrow: strings.arabic ? 'التدريب' : 'TRAINING',
    title: strings.arabic ? 'خططك التدريبية' : 'Your training plans',
    subtitle: strings.arabic ? 'حافظ على استمراريتك بخطة تناسب أسبوعك.' : 'Stay consistent with a plan built for your week.',
    cards: [
      const _DemoCard(
        icon: Icons.bolt_rounded,
        title: 'Forge Strong',
        value: '4 days/week • Today: Push day',
      ),
      const _DemoCard(
        icon: Icons.calendar_month_rounded,
        title: 'Next session',
        value: 'Bench press • Rows • Shoulder press',
      ),
    ],
  );
}

class _DemoNutrition extends StatelessWidget {
  const _DemoNutrition({required this.strings});
  final DemoStrings strings;
  @override
  Widget build(BuildContext context) => _DemoColumn(
    eyebrow: strings.arabic ? 'التغذية' : 'FUEL',
    title: strings.arabic ? 'غذِّ تدريبك' : 'Fuel your training',
    subtitle: strings.arabic ? 'تابع ما يدعم أداءك.' : 'Track what supports your performance.',
    cards: [
      const _DemoCard(
        icon: Icons.local_fire_department_rounded,
        title: 'Daily summary',
        value: '1,840 / 2,400 kcal • 128g protein',
      ),
      const _DemoCard(
        icon: Icons.restaurant_menu_rounded,
        title: 'Today’s food',
        value: 'Greek yogurt • Chicken bowl • Oats',
      ),
    ],
  );
}

class _DemoProgress extends StatelessWidget {
  const _DemoProgress({required this.strings});
  final DemoStrings strings;
  @override
  Widget build(BuildContext context) => _DemoColumn(
    eyebrow: strings.arabic ? 'الرؤى' : 'INSIGHTS',
    title: strings.arabic ? 'تقدمك' : 'Your progress',
    subtitle: strings.arabic ? 'رؤية واضحة للجهد الذي بذلته.' : 'A clear view of the work you have put in.',
    cards: [
      const _DemoCard(
        icon: Icons.check_circle_rounded,
        title: 'Sessions',
        value: '12 completed',
      ),
      const _DemoCard(
        icon: Icons.trending_up_rounded,
        title: 'Volume',
        value: '18,420 kg • +14% this month',
      ),
      const _DemoCard(
        icon: Icons.emoji_events_rounded,
        title: 'Best lift',
        value: 'Bench press • 82.5 kg',
      ),
    ],
  );
}

class _DemoProfile extends StatelessWidget {
  const _DemoProfile({required this.strings});
  final DemoStrings strings;
  @override
  Widget build(BuildContext context) => _DemoColumn(
    eyebrow: strings.arabic ? 'ملف الرياضي' : 'ATHLETE PROFILE',
    title: 'Alex Morgan',
    subtitle: strings.arabic ? 'بناء العضلات • متوسط • الوحدات المترية' : 'Build muscle • Intermediate • Metric units',
    cards: [
      const _DemoCard(icon: Icons.height_rounded, title: 'Height', value: '178 cm'),
      const _DemoCard(
        icon: Icons.monitor_weight_outlined,
        title: 'Latest weight',
        value: '76.4 kg',
      ),
      const _DemoCard(
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
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final visibleTitle = rtl ? _arabicTitle(title) : title;
    final visibleValue = rtl ? _arabicValue(value) : value;
    return Semantics(
      container: true,
      label: '$visibleTitle. $visibleValue',
      child: Card(
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
          title: Text(visibleTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(
            visibleValue,
            style: const TextStyle(color: FitForgeColors.muted),
          ),
          trailing: ExcludeSemantics(
            child: Icon(rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded),
          ),
        ),
      ),
    );
  }
}

String _arabicTitle(String value) => const {
  'Training plan': 'خطة التدريب',
  'Nutrition': 'التغذية',
  'Progress': 'التقدم',
  'Forge Strong': 'Forge Strong',
  'Next session': 'الجلسة القادمة',
  'Daily summary': 'الملخص اليومي',
  'Today’s food': 'طعام اليوم',
  'Sessions': 'الجلسات',
  'Volume': 'الحجم التدريبي',
  'Best lift': 'أفضل رفعة',
  'Height': 'الطول',
  'Latest weight': 'آخر وزن',
  'Goal': 'الهدف',
}[value] ?? value;

String _arabicValue(String value) => const {
  'Push day • 4 exercises': 'يوم الدفع • ٤ تمارين',
  '1,840 / 2,400 kcal': '١٬٨٤٠ / ٢٬٤٠٠ سعرة',
  '12 sessions this month': '١٢ جلسة هذا الشهر',
  '4 days/week • Today: Push day': '٤ أيام أسبوعيًا • اليوم: يوم الدفع',
  'Bench press • Rows • Shoulder press': 'ضغط صدر • سحب • ضغط كتف',
  '1,840 / 2,400 kcal • 128g protein': '١٬٨٤٠ / ٢٬٤٠٠ سعرة • ١٢٨غ بروتين',
  'Greek yogurt • Chicken bowl • Oats': 'زبادي يوناني • طبق دجاج • شوفان',
  '12 completed': '١٢ مكتملة',
  '18,420 kg • +14% this month': '١٨٬٤٢٠ كغ • +١٤٪ هذا الشهر',
  'Bench press • 82.5 kg': 'ضغط صدر • ٨٢٫٥ كغ',
  '178 cm': '١٧٨ سم',
  '76.4 kg': '٧٦٫٤ كغ',
  'Build your strongest self': 'ابنِ أقوى نسخة منك',
}[value] ?? value;
