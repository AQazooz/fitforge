import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitforge/app/fitforge_theme.dart';
import 'package:fitforge/app/responsive.dart';
import 'package:fitforge/features/demo/presentation/demo_preview_page.dart';

void main() {
  testWidgets('shared page uses compact and wide horizontal padding', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    await tester.pumpWidget(
      MaterialApp(
        theme: FitForgeTheme.dark,
        home: const FitForgePage(
          child: SizedBox(width: double.infinity, key: Key('content')),
        ),
      ),
    );
    expect(tester.getTopLeft(find.byKey(const Key('content'))).dx, 16);

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(const Key('content'))).dx, 50);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets(
    'demo preview switches navigation for compact and wide screens',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      await tester.pumpWidget(
        MaterialApp(
          theme: FitForgeTheme.dark,
          home: const MediaQuery(
            data: MediaQueryData(size: Size(390, 800)),
            child: DemoPreviewPage(),
          ),
        ),
      );
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(
        MaterialApp(
          theme: FitForgeTheme.dark,
          home: const MediaQuery(
            data: MediaQueryData(size: Size(1200, 800)),
            child: DemoPreviewPage(),
          ),
        ),
      );
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      addTearDown(() => tester.binding.setSurfaceSize(null));
    },
  );
}
