import 'package:flutter/material.dart';

import '../../../app/fitforge_theme.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            right: -140,
            top: -180,
            child: _Glow(size: 430, color: Color(0x2935E878)),
          ),
          const Positioned(
            left: -180,
            bottom: -210,
            child: _Glow(size: 460, color: Color(0x1FB7F34A)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 820;
                      final form = ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Card(
                          color: FitForgeColors.surface.withValues(alpha: .92),
                          child: Padding(
                            padding: EdgeInsets.all(wide ? 36 : 24),
                            child: child,
                          ),
                        ),
                      );
                      if (!wide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _BrandIntro(title: title, subtitle: subtitle),
                            const SizedBox(height: 28),
                            form,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: _BrandIntro(
                              title: title,
                              subtitle: subtitle,
                            ),
                          ),
                          const SizedBox(width: 72),
                          Expanded(child: form),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandIntro extends StatelessWidget {
  const _BrandIntro({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const FitForgeLogo(),
        const SizedBox(height: 32),
        Text(
          title,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: FitForgeColors.muted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class FitForgeLogo extends StatelessWidget {
  const FitForgeLogo({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compact ? 38 : 46,
        height: compact ? 38 : 46,
        decoration: BoxDecoration(
          color: FitForgeColors.lime,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.bolt_rounded, color: Color(0xFF162000)),
      ),
      const SizedBox(width: 12),
      Text(
        'FITFORGE',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    ],
  );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 50)],
    ),
  );
}
