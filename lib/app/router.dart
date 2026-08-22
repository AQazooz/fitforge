import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/dashboard/presentation/home_page.dart';
import '../features/profile/presentation/profile_setup_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier();
  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = SupabaseConfig.client?.auth.currentSession;
      final isAuthenticated = session != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isProfileRoute = state.matchedLocation == '/profile-setup';

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/profile-setup';
      if (!isAuthenticated && isProfileRoute) return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );

  ref.onDispose(() {
    refresh.dispose();
    router.dispose();
  });
  return router;
});

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    final client = SupabaseConfig.client;
    if (client == null) return;
    _subscription = client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  StreamSubscription<AuthState>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
