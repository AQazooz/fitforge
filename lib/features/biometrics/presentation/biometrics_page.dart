import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/biometrics_repository.dart';

class BiometricsPage extends StatefulWidget {
  const BiometricsPage({super.key});

  @override
  State<BiometricsPage> createState() => _BiometricsPageState();
}

class _BiometricsPageState extends State<BiometricsPage> {
  late final BiometricsRepository _repository;
  late Future<List<Map<String, dynamic>>> _history;

  @override
  void initState() {
    super.initState();
    _repository = BiometricsRepository(Supabase.instance.client);
    _history = _repository.getHistory();
  }

  void _refresh() => setState(() => _history = _repository.getHistory());

  Future<void> _add() async {
    final result = await showDialog<_MetricFormResult>(
      context: context,
      builder: (_) => const _MetricDialog(),
    );
    if (result == null) return;

    try {
      await _repository.addMeasurement(
        measuredAt: result.date,
        weightKg: result.weightKg,
        bodyFatPct: result.bodyFatPct,
        muscleMassKg: result.muscleMassKg,
        waistCm: result.waistCm,
        notes: result.notes,
      );
      _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save measurement: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Body metrics')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add measurement'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _history,
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

          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          if (rows.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.monitor_weight_outlined, size: 64),
                  SizedBox(height: 16),
                  Center(child: Text('Add your first body measurement.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                final date = DateTime.tryParse(
                  '${row['measured_at']}',
                )?.toLocal();
                final title = date == null
                    ? 'Measurement'
                    : '${date.day}/${date.month}/${date.year}';
                return Card(
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text(
                      'Weight ${_value(row['weight_kg'], ' kg')} • '
                      'Fat ${_value(row['body_fat_pct'], '%')} • '
                      'Muscle ${_value(row['muscle_mass_kg'], ' kg')}',
                    ),
                    trailing: Text(_value(row['waist_cm'], ' cm')),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  static String _value(dynamic value, String suffix) {
    if (value == null) return '—';
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    return parsed == null ? '—' : '${parsed.toStringAsFixed(1)}$suffix';
  }
}

class _MetricFormResult {
  const _MetricFormResult({
    required this.date,
    required this.weightKg,
    this.bodyFatPct,
    this.muscleMassKg,
    this.waistCm,
    this.notes,
  });

  final DateTime date;
  final double weightKg;
  final double? bodyFatPct;
  final double? muscleMassKg;
  final double? waistCm;
  final String? notes;
}

class _MetricDialog extends StatefulWidget {
  const _MetricDialog();

  @override
  State<_MetricDialog> createState() => _MetricDialogState();
}

class _MetricDialogState extends State<_MetricDialog> {
  final _formKey = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _bodyFat = TextEditingController();
  final _muscle = TextEditingController();
  final _waist = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    for (final controller in [_weight, _bodyFat, _muscle, _waist, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _positive(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty)
      return required ? 'Required' : null;
    final number = double.tryParse(value);
    return number == null || number <= 0 ? 'Enter a valid value' : null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Body measurement'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              TextFormField(
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                validator: (value) => _positive(value, required: true),
              ),
              TextFormField(
                controller: _bodyFat,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Body fat (%)'),
                validator: _positive,
              ),
              TextFormField(
                controller: _muscle,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Muscle mass (kg)',
                ),
                validator: _positive,
              ),
              TextFormField(
                controller: _waist,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Waist (cm)'),
                validator: _positive,
              ),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
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
              _MetricFormResult(
                date: _date,
                weightKg: double.parse(_weight.text),
                bodyFatPct: double.tryParse(_bodyFat.text),
                muscleMassKg: double.tryParse(_muscle.text),
                waistCm: double.tryParse(_waist.text),
                notes: _notes.text,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
