import 'package:flutter_test/flutter_test.dart';

import 'package:fitforge/app/router.dart';

void main() {
  test(
    'unauthenticated users stay on auth routes and leave protected routes',
    () async {
      expect(
        await appRedirect(
          location: '/login',
          isAuthenticated: false,
          demoMode: false,
        ),
        isNull,
      );
      expect(
        await appRedirect(
          location: '/home',
          isAuthenticated: false,
          demoMode: false,
        ),
        '/login',
      );
    },
  );

  test(
    'authenticated users are sent through profile setup when needed',
    () async {
      expect(
        await appRedirect(
          location: '/login',
          isAuthenticated: true,
          demoMode: false,
          hasProfile: () async => false,
        ),
        '/profile-setup',
      );
      expect(
        await appRedirect(
          location: '/workouts',
          isAuthenticated: true,
          demoMode: false,
          hasProfile: () async => true,
        ),
        isNull,
      );
    },
  );

  test('demo route is gated independently from auth state', () async {
    expect(
      await appRedirect(
        location: '/demo',
        isAuthenticated: false,
        demoMode: false,
      ),
      '/login',
    );
    expect(
      await appRedirect(
        location: '/demo',
        isAuthenticated: false,
        demoMode: true,
      ),
      isNull,
    );
  });
}
