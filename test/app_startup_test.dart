import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitforge/app/app.dart';

void main() {
  testWidgets('FitForge starts inside ProviderScope on the login route', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FitForgeApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
