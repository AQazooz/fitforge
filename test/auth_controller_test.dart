import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitforge/features/auth/presentation/auth_controller.dart';

void main() {
  test('auth controller reports a clear offline configuration error', () async {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(null)],
    );
    addTearDown(container.dispose);

    final controller = container.read(authControllerProvider);
    await expectLater(
      controller.signIn(email: 'athlete@example.com', password: 'secret123'),
      throwsA(isA<StateError>()),
    );
  });
}
