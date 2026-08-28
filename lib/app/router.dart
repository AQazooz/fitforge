import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/config/env.dart';
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
import '../features/demo/presentation/demo_preview_page.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(SupabaseConfig.client!),
);

Future<String?> appRedirect({
  required String location,
  required bool isAuthenticated,
  required bool demoMode,
  Future<bool> Function()? hasProfile,
}) async {
  if (location == '/demo') return demoMode ? null : '/login';
  final isAuthRoute = location == '/login' || location == '/register';
  final isProfileRoute = location == '/profile-setup';
  final isProtectedRoute = {
    '/home',
    '/workouts',
    '/progress',
    '/nutrition',
    '/nutrition-coach',
    '/foods',
    '/biometrics',
    '/profile',
  }.contains(location);

  if (!isAuthenticated) return isAuthRoute ? null : '/login';
  if (isAuthRoute) {
    return await hasProfile!() ? '/home' : '/profile-setup';
  }
  if (isProfileRoute) {
    return await hasProfile!() ? '/home' : null;
  }
  if (isProtectedRoute) {
    return await hasProfile!() ? null : '/profile-setup';
  }
  return '/home';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier();
  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) async {
      final client = SupabaseConfig.client;
      final isAuthenticated = client?.auth.currentSession != null;
      return appRedirect(
        location: state.matchedLocation,
        isAuthenticated: isAuthenticated,
        demoMode: AppEnv.demoMode,
        hasProfile: () => ref
            .read(profileRepositoryProvider)
            .hasCurrentProfile(),
      );
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      if (AppEnv.demoMode)
        GoRoute(path: '/demo', builder: (_, _) => const DemoPreviewPage()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
      GoRoute(
        path: '/profile-setup',
        builder: (_, _) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const ProfileSetupPage(editing: true),
      ),
      GoRoute(path: '/home', builder: (_, _) => const HomePage()),
      GoRoute(path: '/workouts', builder: (_, _) => const WorkoutsPage()),
      GoRoute(path: '/progress', builder: (_, _) => const ProgressPage()),
      GoRoute(path: '/nutrition', builder: (_, _) => const NutritionPage()),
      GoRoute(
        path: '/nutrition-coach',
        builder: (_, _) => const NutritionCoachPage(),
      ),
      GoRoute(path: '/foods', builder: (_, _) => const FoodSearchPage()),
      GoRoute(path: '/biometrics', builder: (_, _) => const BiometricsPage()),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Semantics(
          container: true,
          liveRegion: true,
          label: 'خطأ في التنقل',
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'تعذر العثور على هذه الصفحة\n${state.uri}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
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
    _subscription = client.auth.onAuthStateChange.listen(
      (_) => notifyListeners(),
    );
  }

  StreamSubscription<AuthState>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
