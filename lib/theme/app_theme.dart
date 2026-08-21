import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const purple = Color(0xFF8B5CF6);
  static const teal = Color(0xFF14B8A6);
  static const blue = Color(0xFF3B82F6);
  static const pink = Color(0xFFEC4899);
  static const orange = Color(0xFFF97316);
  static const green = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);
  static const dangerDark = Color(0xFFDC2626);
  static const indigo = Color(0xFF6366F1);

  static Color accentFrom(String name) {
    switch (name) {
      case 'teal': return teal;
      case 'blue': return blue;
      case 'pink': return pink;
      case 'orange': return orange;
      case 'green': return green;
      case 'indigo': return indigo;
      default: return purple;
    }
  }
}

class AppTheme {
  static ThemeData light({required String accent, bool danger = false}) {
    final a = AppColors.accentFrom(accent);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: a, brightness: Brightness.light),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(centerTitle: true, backgroundColor: a.withOpacity(0.08)),
    );
  }

  static ThemeData dark({required String accent, bool danger = false}) {
    final a = AppColors.accentFrom(accent);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: a, brightness: Brightness.dark),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      scaffoldBackgroundColor: const Color(0xFF0F0F14),
      appBarTheme: AppBarTheme(centerTitle: true, backgroundColor: a.withOpacity(0.12)),
    );
  }
}
