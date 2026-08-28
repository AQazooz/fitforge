import 'package:flutter/material.dart';

abstract final class FitForgeColors {
  static const background = Color(0xFF090D0B);
  static const surface = Color(0xFF111713);
  static const surfaceStrong = Color(0xFF182019);
  static const lime = Color(0xFFB7F34A);
  static const mint = Color(0xFF6DE8A2);
  static const text = Color(0xFFF4F7F2);
  static const muted = Color(0xFF9BA89E);
  static const outline = Color(0xFF29342C);
}

abstract final class FitForgeTheme {
  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: FitForgeColors.lime,
          brightness: Brightness.dark,
          surface: FitForgeColors.surface,
        ).copyWith(
          primary: FitForgeColors.lime,
          secondary: FitForgeColors.mint,
          onPrimary: const Color(0xFF172000),
          surface: FitForgeColors.surface,
          onSurface: FitForgeColors.text,
          outline: FitForgeColors.outline,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: FitForgeColors.background,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: FitForgeColors.text,
        displayColor: FitForgeColors.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: FitForgeColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: FitForgeColors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FitForgeColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FitForgeColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FitForgeColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FitForgeColors.lime, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: FitForgeColors.surface,
        indicatorColor: Color(0xFF2C3B18),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: FitForgeColors.outline),
    );
  }
}
