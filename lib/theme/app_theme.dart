import 'package:flutter/material.dart';

class AppTheme {
  // Colors inspired by the provided logo
  static const Color brandYellow = Color(0xFFFFC107); // Amber-like
  static const Color darkBg = Color(0xFF2B2B2B);
  static const Color darkCard = Color(0xFF363636);

  static ThemeData theme() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandYellow,
        brightness: Brightness.dark,
        primary: brandYellow,
        onPrimary: Colors.black,
        surface: darkCard,
      ),
      scaffoldBackgroundColor: darkBg,
      appBarTheme: const AppBarTheme(backgroundColor: darkBg, elevation: 0),
      cardColor: darkCard,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
    return base.copyWith(
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandYellow,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      iconTheme: const IconThemeData(color: brandYellow),
    );
  }
}

extension BubbleColors on BuildContext {
  Color get bubbleMe => const Color(0xFF444444);
  Color get bubbleOther => const Color(0xFF3A3A3A);
}
