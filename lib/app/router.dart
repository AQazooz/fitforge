import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/biometrics/presentation/biometrics_page.dart';
import '../features/dashboard/presentation/home_page.dart';
import '../features/nutrition/presentation/food_search_page.dart';
import '../features/nutrition/presentation/nutrition_coach_page.dart';
import '../features/nutrition/presentation/nutrition_page.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/presentation/profile_setup_page.dart';
import '../features/workouts/presentation/progress_page.dart';
import '../features/workouts/presentation/workouts_page.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository(SupabaseConfig.client!));

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier();
  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) async {
      final client = SupabaseConfig.client;
      final isAuthenticated = client?.auth.currentSession != null;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/register';
      final isProfileRoute = location == '/profile-setup';
      final isProtectedRoute = {
        '/home', '/workouts', '/progress', '/nutrition', '/nutrition-coach', '/foods', '/biometrics'
      }.contains(location);

      if (!isAuthenticated) return isAuthRoute ? null : '/login';
      if (isAuthRoute) {
        final hasProfile = await ref.read(profileRepositoryProvider).hasCurrentProfile();
        return hasProfile ? '/home' : '/profile-setup';
      }
      if (isProfileRoute) {
        final hasProfile = await ref.read(profileRepositoryProvider).hasCurrentProfile();
        return hasProfile ? '/home' : null;
      }
      if (isProtectedRoute) {
        final hasProfile = await ref.read(profileRepositoryProvider).hasCurrentProfile();
        return hasProfile ? null : '/profile-setup';
      }
      return '/home';
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupPage()),
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      GoRoute(path: '/workouts', builder: (_, __) => const WorkoutsPage()),
      GoRoute(path: '/progress', builder: (_, __) => const ProgressPage()),
      GoRoute(path: '/nutrition', builder: (_, __) => const NutritionPage()),
      GoRoute(path: '/nutrition-coach', builder: (_, __) => const NutritionCoachPage()),
      GoRoute(path: '/foods', builder: (_, __) => const FoodSearchPage()),
      GoRoute(path: '/biometrics', builder: (_, __) => const BiometricsPage()),
    ],
    errorBuilder: (_, state) => Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
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
    _subscription = client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  StreamSubscription<AuthState>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
