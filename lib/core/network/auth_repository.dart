import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email.trim(), password: password);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) => _client.auth.signUp(email: email.trim(), password: password);

  Future<void> signOut() => _client.auth.signOut();
}
