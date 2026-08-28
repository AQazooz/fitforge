import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/nutrition_repository.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  late final NutritionRepository _repository;
  late DateTime _selectedDay;
  late Future<NutritionDay> _dayFuture;

  @override
  void initState() {
    super.initState();
    _repository = NutritionRepository(Supabase.instance.client);
    _selectedDay = DateTime.now();
    _dayFuture = _load();
  }

  Future<NutritionDay> _load() => _repository.loadDay(_selectedDay);

  void _refresh() => setState(() => _dayFuture = _load());

  void _changeDay(int offset) {
    setState(() {
      _selectedDay = _selectedDay.add(Duration(days: offset));
      _dayFuture = _load();
    });
  }

  Future<void> _addFood() async {
    final result = await showDialog<_FoodFormResult>(
      context: context,
      builder: (_) => const _FoodDialog(),
    );
    if (result == null) return;
    try {
      await _repository.addFood(
        consumedAt: DateTime(
          _selectedDay.year,
          _selectedDay.month,
          _selectedDay.day,
          result.time.hour,
          result.time.minute,
        ),
        foodName: result.foodName,
        mealType: result.mealType,
        calories: result.calories,
        proteinG: result.protein,
        carbsG: result.carbs,
        fatG: result.fat,
        servingSize: result.servingSize,
      );
      _refresh();
    } catch (error) {
      if (mounted) _showError('Could not save food: $error');
    }
  }

  Future<void> _editTarget() async {
    final result = await showDialog<_TargetFormResult>(
      context: context,
      builder: (_) => const _TargetDialog(),
    );
    if (result == null) return;
    try {
      await _repository.saveTarget(
        effectiveFrom: _selectedDay,
        calories: result.calories,
        proteinG: result.protein,
        carbsG: result.carbs,
        fatG: result.fat,
        fiberG: result.fiber,
      );
      _refresh();
    } catch (error) {
      if (mounted) _showError('Could not save nutrition target: $error');
    }
  }

  Future<void> _deleteFood(String id) async {
    try {
      await _repository.deleteFood(id);
      _refresh();
    } catch (error) {
      if (mounted) _showError('Could not delete food: $error');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [
          IconButton(
            onPressed: _editTarget,
            icon: const Icon(Icons.tune),
            tooltip: 'Set targets',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFood,
        icon: const Icon(Icons.add),
        label: const Text('Add food'),
      ),
      body: FutureBuilder<NutritionDay>(
        future: _dayFuture,
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

          final day = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _DaySelector(
                  day: _selectedDay,
                  onPrevious: () => _changeDay(-1),
                  onNext: () => _changeDay(1),
                ),
                const SizedBox(height: 16),
                _SummaryCard(day: day),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today\'s food',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('${day.logs.length} entries'),
                  ],
                ),
                const SizedBox(height: 8),
                if (day.logs.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No food logged for this day yet.'),
                    ),
                  )
                else
                  ...day.logs.map((food) {
                    final meal = (food['meal_type'] as String?) ?? 'Meal';
                    final calories = (food['calories'] as num?)?.toInt() ?? 0;
                    final protein =
                        (food['protein_g'] as num?)?.toDouble() ?? 0;
                    return Card(
                      child: ListTile(
                        title: Text('${food['food_name']}'),
                        subtitle: Text(
                          '$meal • ${food['serving_size'] ?? ''} • ${protein.toStringAsFixed(0)}g protein',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$calories kcal'),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () =>
                                  _deleteFood(food['id'] as String),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
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

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.day,
    required this.onPrevious,
    required this.onNext,
  });
  final DateTime day;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(day, DateTime.now());
    final label = isToday ? 'Today' : '${day.day}/${day.month}/${day.year}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.day});
  final NutritionDay day;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daily summary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text('${day.calories} kcal'),
              ],
            ),
            const SizedBox(height: 16),
            _MacroProgress(
              label: 'Calories',
              consumed: day.calories.toDouble(),
              target: day.targetCalories?.toDouble(),
              unit: 'kcal',
            ),
            _MacroProgress(
              label: 'Protein',
              consumed: day.protein,
              target: day.targetProtein?.toDouble(),
              unit: 'g',
            ),
            _MacroProgress(
              label: 'Carbs',
              consumed: day.carbs,
              target: day.targetCarbs?.toDouble(),
              unit: 'g',
            ),
            _MacroProgress(
              label: 'Fat',
              consumed: day.fat,
              target: day.targetFat?.toDouble(),
              unit: 'g',
            ),
            if (day.target == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const _TargetDialog(),
                  ),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Set your daily targets'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MacroProgress extends StatelessWidget {
  const _MacroProgress({
    required this.label,
    required this.consumed,
    required this.target,
    required this.unit,
  });
  final String label;
  final double consumed;
  final double? target;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final ratio = target == null || target! <= 0
        ? 0.0
        : (consumed / target!).clamp(0.0, 1.0);
    final targetText = target == null
        ? 'No target'
        : '${target!.toStringAsFixed(0)} $unit';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('${consumed.toStringAsFixed(0)} / $targetText'),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: target == null ? null : ratio),
        ],
      ),
    );
  }
}

class _FoodFormResult {
  const _FoodFormResult({
    required this.foodName,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    required this.time,
  });
  final String foodName;
  final String mealType;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String servingSize;
  final TimeOfDay time;
}

class _FoodDialog extends StatefulWidget {
  const _FoodDialog();
  @override
  State<_FoodDialog> createState() => _FoodDialogState();
}

class _FoodDialogState extends State<_FoodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _serving = TextEditingController(text: '1 serving');
  String _mealType = 'Meal';

  @override
  void dispose() {
    for (final controller in [
      _name,
      _calories,
      _protein,
      _carbs,
      _fat,
      _serving,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add food'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Food name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _mealType,
                decoration: const InputDecoration(labelText: 'Meal type'),
                items: const ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Meal']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _mealType = v!),
              ),
              TextFormField(
                controller: _serving,
                decoration: const InputDecoration(labelText: 'Serving size'),
              ),
              TextFormField(
                controller: _calories,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories'),
                validator: _numberValidator,
              ),
              TextFormField(
                controller: _protein,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Protein (g)'),
                validator: _doubleValidator,
              ),
              TextFormField(
                controller: _carbs,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Carbs (g)'),
                validator: _doubleValidator,
              ),
              TextFormField(
                controller: _fat,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Fat (g)'),
                validator: _doubleValidator,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _FoodFormResult(
                foodName: _name.text,
                mealType: _mealType,
                calories: int.parse(_calories.text),
                protein: double.parse(_protein.text),
                carbs: double.parse(_carbs.text),
                fat: double.parse(_fat.text),
                servingSize: _serving.text,
                time: TimeOfDay.now(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  String? _numberValidator(String? value) {
    final parsed = int.tryParse(value ?? '');
    return parsed == null || parsed < 0 ? 'Enter a valid number' : null;
  }

  String? _doubleValidator(String? value) {
    final parsed = double.tryParse(value ?? '');
    return parsed == null || parsed < 0 ? 'Enter a valid number' : null;
  }
}

class _TargetFormResult {
  const _TargetFormResult({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
}

class _TargetDialog extends StatefulWidget {
  const _TargetDialog();
  @override
  State<_TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<_TargetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _fiber = TextEditingController(text: '30');

  @override
  void dispose() {
    for (final controller in [_calories, _protein, _carbs, _fat, _fiber]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validate(String? value) {
    final parsed = double.tryParse(value ?? '');
    return parsed == null || parsed < 0 ? 'Enter a valid number' : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Daily nutrition targets'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _calories,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories'),
                validator: (v) =>
                    int.tryParse(v ?? '') == null ? 'Enter calories' : null,
              ),
              TextFormField(
                controller: _protein,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Protein (g)'),
                validator: _validate,
              ),
              TextFormField(
                controller: _carbs,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Carbs (g)'),
                validator: _validate,
              ),
              TextFormField(
                controller: _fat,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Fat (g)'),
                validator: _validate,
              ),
              TextFormField(
                controller: _fiber,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Fiber (g)'),
                validator: _validate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _TargetFormResult(
                calories: int.parse(_calories.text),
                protein: double.parse(_protein.text),
                carbs: double.parse(_carbs.text),
                fat: double.parse(_fat.text),
                fiber: double.parse(_fiber.text),
              ),
            );
          },
          child: const Text('Save target'),
        ),
      ],
    );
  }
}
