import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/nutrition_intelligence.dart';
import '../data/nutrition_repository.dart';

class NutritionCoachPage extends StatefulWidget {
  const NutritionCoachPage({super.key});

  @override
  State<NutritionCoachPage> createState() => _NutritionCoachPageState();
}

class _NutritionCoachPageState extends State<NutritionCoachPage> {
  late final NutritionRepository _repository;
  late Future<NutritionRecommendation> _recommendation;

  @override
  void initState() {
    super.initState();
    _repository = NutritionRepository(Supabase.instance.client);
    _recommendation = _buildRecommendation();
  }

  Future<NutritionRecommendation> _buildRecommendation() async {
    final context = await _repository.loadNutritionContext();
    return NutritionIntelligence.calculate(
      profile: context['profile'] as Map<String, dynamic>,
      biometrics: context['biometrics'] as Map<String, dynamic>?,
    );
  }

  Future<void> _apply(NutritionRecommendation recommendation) async {
    try {
      await _repository.saveTarget(
        effectiveFrom: DateTime.now(),
        calories: recommendation.calories,
        proteinG: recommendation.proteinG,
        carbsG: recommendation.carbsG,
        fatG: recommendation.fatG,
        fiberG: recommendation.fiberG,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily nutrition target saved.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save target: $error')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Coach')),
      body: FutureBuilder<NutritionRecommendation>(
        future: _recommendation,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) {
            return Center(
              child: FilledButton(
                onPressed: () =>
                    setState(() => _recommendation = _buildRecommendation()),
                child: const Text('Retry'),
              ),
            );
          }
          final recommendation = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Your starting nutrition target',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'An estimate based on your FitForge profile and latest body measurement. Review it and adjust it when needed.',
              ),
              const SizedBox(height: 20),
              _TargetCard(
                label: 'Calories',
                value: '${recommendation.calories} kcal',
              ),
              _TargetCard(
                label: 'Protein',
                value: '${recommendation.proteinG.toStringAsFixed(0)} g',
              ),
              _TargetCard(
                label: 'Carbs',
                value: '${recommendation.carbsG.toStringAsFixed(0)} g',
              ),
              _TargetCard(
                label: 'Fat',
                value: '${recommendation.fatG.toStringAsFixed(0)} g',
              ),
              _TargetCard(
                label: 'Fiber',
                value: '${recommendation.fiberG.toStringAsFixed(0)} g',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(recommendation.method),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _apply(recommendation),
                icon: const Icon(Icons.check),
                label: const Text('Use these targets'),
              ),
              const SizedBox(height: 8),
              const Text(
                'FitForge treats these values as a starting estimate, not a medical prescription.',
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    ),
  );
}
