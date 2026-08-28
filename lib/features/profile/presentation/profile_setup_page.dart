import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/responsive.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository?>(
  (ref) => ProfileRepository(Supabase.instance.client),
);

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key, this.editing = false});

  final bool editing;

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  DateTime? _dateOfBirth;
  String _unitSystem = 'metric';
  String _trainingLevel = 'beginner';
  String _goal = 'muscle_gain';
  String? _sex;
  bool _saving = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editing) _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final profile = await ref
        .read(profileRepositoryProvider)!
        .getCurrentProfile();
    if (!mounted) return;
    if (profile != null) {
      _nameController.text = '${profile['display_name'] ?? ''}';
      _heightController.text = '${profile['height_cm'] ?? ''}';
      _sex = profile['sex'] as String?;
      _unitSystem = profile['unit_system'] as String? ?? 'metric';
      _trainingLevel = profile['training_level'] as String? ?? 'beginner';
      _goal = profile['goal'] as String? ?? 'muscle_gain';
      final dob = profile['date_of_birth'] as String?;
      _dateOfBirth = dob == null ? null : DateTime.tryParse(dob);
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      initialDate: _dateOfBirth ?? DateTime(2000),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)!
          .upsertProfile(
            displayName: _nameController.text,
            dateOfBirth: _dateOfBirth,
            sex: _sex,
            heightCm: double.tryParse(_heightController.text),
            unitSystem: _unitSystem,
            trainingLevel: _trainingLevel,
            goal: _goal,
          );
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save profile: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dobLabel = _dateOfBirth == null
        ? 'Select date of birth'
        : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing ? 'Edit profile' : 'Set up your profile'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: FitForgePage(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      FitForgeSectionTitle(
                        title: widget.editing
                            ? 'Your profile'
                            : 'Tell us about you',
                        subtitle:
                            'Personalize your workouts, nutrition, and progress tracking.',
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter your name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Date of birth'),
                        subtitle: Text(dobLabel),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                        ),
                        validator: (value) {
                          final height = double.tryParse(value ?? '');
                          return height == null || height < 100 || height > 250
                              ? 'Enter a valid height'
                              : null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _sex,
                        decoration: const InputDecoration(labelText: 'Sex'),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _sex = value),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _trainingLevel,
                        decoration: const InputDecoration(
                          labelText: 'Training level',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'beginner',
                            child: Text('Beginner'),
                          ),
                          DropdownMenuItem(
                            value: 'intermediate',
                            child: Text('Intermediate'),
                          ),
                          DropdownMenuItem(
                            value: 'advanced',
                            child: Text('Advanced'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _trainingLevel = value!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _goal,
                        decoration: const InputDecoration(
                          labelText: 'Primary goal',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'muscle_gain',
                            child: Text('Build muscle'),
                          ),
                          DropdownMenuItem(
                            value: 'fat_loss',
                            child: Text('Lose fat'),
                          ),
                          DropdownMenuItem(
                            value: 'maintenance',
                            child: Text('Maintain'),
                          ),
                          DropdownMenuItem(
                            value: 'performance',
                            child: Text('Performance'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _goal = value!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _unitSystem,
                        decoration: const InputDecoration(labelText: 'Units'),
                        items: const [
                          DropdownMenuItem(
                            value: 'metric',
                            child: Text('Metric (kg / cm)'),
                          ),
                          DropdownMenuItem(
                            value: 'imperial',
                            child: Text('Imperial (lb / in)'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _unitSystem = value!),
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.editing ? 'Save changes' : 'Continue',
                              ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
