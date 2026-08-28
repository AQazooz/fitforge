import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fitforge_theme.dart';
import 'router.dart';

class FitForgeApp extends ConsumerWidget {
  const FitForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'FitForge',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: FitForgeTheme.dark,
    );
  }
}
