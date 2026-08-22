import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/food_catalog_repository.dart';
import '../data/nutrition_repository.dart';

class FoodSearchPage extends StatefulWidget {
  const FoodSearchPage({super.key});

  @override
  State<FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends State<FoodSearchPage> {
  late final FoodCatalogRepository _catalog;
  late final NutritionRepository _nutrition;
  final _search = TextEditingController();
  Future<List<Map<String, dynamic>>>? _results;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _catalog = FoodCatalogRepository(client);
    _nutrition = NutritionRepository(client);
    _results = _catalog.search('');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _runSearch() => setState(() => _results = _catalog.search(_search.text));

  Future<void> _addFood(Map<String, dynamic> food) async {
    final servings = await showDialog<double>(
      context: context,
      builder: (_) => const _ServingDialog(),
    );
    if (servings == null || servings <= 0) return;

    try {
      final factor = servings;
      await _nutrition.addFood(
        consumedAt: DateTime.now(),
        foodName: '${food['name']} (${servings.toStringAsFixed(servings.truncateToDouble() == servings ? 0 : 1)} serving)',
        mealType: 'Meal',
        calories: ((food['calories'] as num).toDouble() * factor).round(),
        proteinG: (food['protein_g'] as num).toDouble() * factor,
        carbsG: (food['carbs_g'] as num).toDouble() * factor,
        fatG: (food['fat_g'] as num).toDouble() * factor,
        servingSize: '${food['serving_size']} × ${servings.toStringAsFixed(1)}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food added to today.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add food: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food database')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _runSearch(),
              decoration: InputDecoration(
                labelText: 'Search food',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _runSearch,
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _results,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: FilledButton.icon(
                      onPressed: _runSearch,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  );
                }

                final foods = snapshot.data ?? const <Map<String, dynamic>>[];
                if (foods.isEmpty) {
                  return const Center(child: Text('No foods found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    return Card(
                      child: ListTile(
                        title: Text('${food['name']}'),
                        subtitle: Text(
                          '${food['serving_size']} • '
                          '${(food['calories'] as num).toInt()} kcal • '
                          '${(food['protein_g'] as num).toStringAsFixed(0)}g protein',
                        ),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => _addFood(food),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServingDialog extends StatefulWidget {
  const _ServingDialog();

  @override
  State<_ServingDialog> createState() => _ServingDialogState();
}

class _ServingDialogState extends State<_ServingDialog> {
  final _controller = TextEditingController(text: '1');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('How many servings?'),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Servings'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(_controller.text);
            if (value == null || value <= 0) return;
            Navigator.pop(context, value);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
