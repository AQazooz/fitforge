import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/profile_repository.dart';

final profilePageRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository(Supabase.instance.client));
final profilePageProvider = FutureProvider<Map<String, dynamic>?>((ref) => ref.read(profilePageRepositoryProvider).getCurrentProfile());

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _height = TextEditingController();
  DateTime? _dob;
  String? _sex;
  String _units = 'metric';
  String _level = 'beginner';
  String _goal = 'muscle_gain';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ref.read(profilePageRepositoryProvider).getCurrentProfile();
      if (profile != null && mounted) {
        _name.text = '${profile['display_name'] ?? ''}';
        _height.text = '${profile['height_cm'] ?? ''}';
        final rawDob = profile['date_of_birth'];
        _dob = rawDob == null ? null : DateTime.tryParse('$rawDob');
        setState(() {
          _sex = profile['sex'] as String?;
          _units = profile['unit_system'] as String? ?? 'metric';
          _level = profile['training_level'] as String? ?? 'beginner';
          _goal = profile['goal'] as String? ?? 'muscle_gain';
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, firstDate: DateTime(1940), lastDate: DateTime.now(), initialDate: _dob ?? DateTime(2000));
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(profilePageRepositoryProvider).upsertProfile(
        displayName: _name.text,
        dateOfBirth: _dob,
        sex: _sex,
        heightCm: double.tryParse(_height.text),
        unitSystem: _units,
        trainingLevel: _level,
        goal: _goal,
      );
      ref.invalidate(profilePageProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update profile: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _height.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Your profile', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Keep these details accurate so FitForge can personalize your training and nutrition.'),
            const SizedBox(height: 24),
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Display name'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null),
            const SizedBox(height: 16),
            ListTile(contentPadding: EdgeInsets.zero, title: const Text('Date of birth'), subtitle: Text(_dob == null ? 'Not set' : '${_dob!.day}/${_dob!.month}/${_dob!.year}'), trailing: const Icon(Icons.calendar_today), onTap: _pickDate),
            const SizedBox(height: 8),
            TextFormField(controller: _height, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Height (cm)'), validator: (v) { final n = double.tryParse(v ?? ''); return n == null || n < 100 || n > 250 ? 'Enter a valid height' : null; }),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(initialValue: _sex, decoration: const InputDecoration(labelText: 'Sex'), items: const [DropdownMenuItem(value: 'male', child: Text('Male')), DropdownMenuItem(value: 'female', child: Text('Female')), DropdownMenuItem(value: 'other', child: Text('Other'))], onChanged: (v) => setState(() => _sex = v)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(initialValue: _level, decoration: const InputDecoration(labelText: 'Training level'), items: const [DropdownMenuItem(value: 'beginner', child: Text('Beginner')), DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')), DropdownMenuItem(value: 'advanced', child: Text('Advanced'))], onChanged: (v) => setState(() => _level = v!)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(initialValue: _goal, decoration: const InputDecoration(labelText: 'Primary goal'), items: const [DropdownMenuItem(value: 'muscle_gain', child: Text('Build muscle')), DropdownMenuItem(value: 'fat_loss', child: Text('Lose fat')), DropdownMenuItem(value: 'maintenance', child: Text('Maintain')), DropdownMenuItem(value: 'performance', child: Text('Performance'))], onChanged: (v) => setState(() => _goal = v!)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(initialValue: _units, decoration: const InputDecoration(labelText: 'Units'), items: const [DropdownMenuItem(value: 'metric', child: Text('Metric (kg / cm)')), DropdownMenuItem(value: 'imperial', child: Text('Imperial (lb / in)'))], onChanged: (v) => setState(() => _units = v!)),
            const SizedBox(height: 28),
            FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save changes')),
          ],
        ),
      ),
    );
  }
}
