import 'package:flutter/material.dart';

class DiverrTheme {
  // Cores principais do Diverr
  static const Color primary = Color(0xFF087EA4);
  static const Color secondary = Color(0xFF35B8D4);
  static const Color background = Color(0xFFF5FAFC);
  static const Color dark = Color(0xFF0B2633);

  static ThemeData light = ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: background,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: dark,
      elevation: 0,
      centerTitle: false,
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    fontFamily: 'Roboto',
  );
}