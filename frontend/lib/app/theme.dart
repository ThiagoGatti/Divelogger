import 'package:flutter/material.dart';

class DiverrTheme {
  DiverrTheme._();

  // Paleta da marca
  static const Color primary = Color(0xFF087EA4);
  static const Color secondary = Color(0xFF35B8D4);
  static const Color ocean = Color(0xFF8ED8E5);
  static const Color background = Color(0xFFF5FAFC);
  static const Color dark = Color(0xFF0B2633);
  static const Color surface = Colors.white;

  // Semânticas
  static const Color success = Color(0xFF1B9E6B);
  static const Color warning = Color(0xFFF2A100);
  static const Color danger = Color(0xFFD64545);
  static const Color muted = Color(0xFF6B7F8A);
  static const Color gold = Color(0xFFE5A400);

  // Modo noturno
  static const Color darkBackground = Color(0xFF0B1A22);
  static const Color darkSurface = Color(0xFF132A35);
  static const Color darkSoft = Color(0xFF1B3644);
  static const Color darkText = Color(0xFFE6F1F5);
  static const Color darkAccent = Color(0xFF3FB8D6);

  // Medidas
  static const double radius = 20;
  static const double radiusSmall = 14;

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: dark.withOpacity(.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF065F7E), primary, secondary],
  );

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? darkBackground : background;
    final surfaceColor = isDark ? darkSurface : Colors.white;
    final soft = isDark ? darkSoft : background;
    final text = isDark ? darkText : dark;
    final accent = isDark ? darkAccent : primary;
    final onAccent = isDark ? const Color(0xFF062029) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(.10) : dark.withOpacity(.08);

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      onPrimary: onAccent,
      secondary: secondary,
      error: danger,
      surface: surfaceColor,
      onSurface: text,
      surfaceContainerHighest: soft,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: text, fontSize: 19, fontWeight: FontWeight.w800),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: danger, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: accent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: accent.withOpacity(.18),
        side: BorderSide(color: border),
        labelStyle: TextStyle(fontWeight: FontWeight.w600, color: text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        height: 68,
        indicatorColor: accent.withOpacity(.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? accent : muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(color: states.contains(WidgetState.selected) ? accent : muted);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? darkSoft : dark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: onAccent,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: DividerThemeData(color: border, space: 1),
    );
  }
}

/// Cores que se adaptam ao tema claro/escuro. Use no lugar de Colors.white (fundos) e de
/// DiverrTheme.background / DiverrTheme.dark (texto) em telas e componentes.
extension DiverrContext on BuildContext {
  ColorScheme get _scheme => Theme.of(this).colorScheme;

  /// Fundo de cartões e painéis (branco no claro, azul-escuro no noturno).
  Color get surfaceColor => _scheme.surface;

  /// Preenchimento suave sobre um cartão (campos, miniaturas, blocos secundários).
  Color get softFill => _scheme.surfaceContainerHighest;

  /// Cor de texto principal.
  Color get strongText => _scheme.onSurface;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
