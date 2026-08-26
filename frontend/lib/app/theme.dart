import 'package:flutter/material.dart';

class DiverrTheme {
  static const Color primary = Color(0xFF087EA4);
  static const Color secondary = Color(0xFF35B8D4);
  static const Color ocean = Color(0xFF8ED8E5);
  static const Color background = Color(0xFFF5FAFC);
  static const Color dark = Color(0xFF0B2633);
  static const Color surface = Colors.white;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light).copyWith(primary: primary, secondary: secondary);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(backgroundColor: background, foregroundColor: dark, elevation: 0, centerTitle: false),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primary, width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontWeight: FontWeight.w800))),
      cardTheme: CardThemeData(elevation: 0, color: surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      fontFamily: 'Roboto',
    );
  }
}
