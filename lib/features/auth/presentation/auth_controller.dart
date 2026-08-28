import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/network/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  final client = SupabaseConfig.client;
  return client == null ? null : AuthRepository(client);
});

final authStateProvider = StreamProvider<AuthState?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  if (repository == null) {
    return Stream<AuthState?>.value(null);
  }
  return repository.authStateChanges.map((event) => event);
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

class AuthController {
  AuthController(this._ref);

  final Ref _ref;

  AuthRepository? get _repository => _ref.read(authRepositoryProvider);

  Future<void> signIn({required String email, required String password}) async {
    final repository = _repository;
    if (repository == null) {
      throw StateError('Supabase is not configured.');
    }
    await repository.signIn(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) async {
    final repository = _repository;
    if (repository == null) {
      throw StateError('Supabase is not configured.');
    }
    await repository.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    await repository.signOut();
  }
}
