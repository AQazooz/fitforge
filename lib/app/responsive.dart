import 'package:flutter/material.dart';

import 'fitforge_theme.dart';

class FitForgePage extends StatelessWidget {
  const FitForgePage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 40 : 16,
                8,
                wide ? 40 : 16,
                32,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class FitForgeSectionTitle extends StatelessWidget {
  const FitForgeSectionTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: const TextStyle(color: FitForgeColors.muted)),
        ],
      ],
    );
  }
}

class FitForgeSurface extends StatelessWidget {
  const FitForgeSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}
