import 'package:flutter/material.dart';

class NovaTheme {
  static const accent = Color(0xFF8B6CFF);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: const Color(0xFF111116),
    );
    return _base(scheme, const Color(0xFF0A0A0E), const Color(0xFF141419), const Color(0xFF17171E));
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
      surface: const Color(0xFFF9F8FC),
    );
    return _base(scheme, const Color(0xFFF4F2F8), Colors.white, const Color(0xFFECE9F2));
  }

  static ThemeData _base(ColorScheme scheme, Color scaffold, Color card, Color field) => ThemeData(
        brightness: scheme.brightness,
        scaffoldBackgroundColor: scaffold,
        colorScheme: scheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(backgroundColor: scaffold, surfaceTintColor: Colors.transparent, centerTitle: false),
        navigationBarTheme: NavigationBarThemeData(backgroundColor: card, indicatorColor: accent.withValues(alpha: .18), height: 72),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: field,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        ),
        cardTheme: CardThemeData(
          color: card,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .45))),
        ),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      );
}
