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
    final primary = AppColors.accentFrom(accent);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(centerTitle: true, backgroundColor: primary.withOpacity(0.08)),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static ThemeData dark({required String accent, bool danger = false}) {
    final primary = AppColors.accentFrom(accent);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF0F0F14),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(centerTitle: true, backgroundColor: primary.withOpacity(0.12)),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A22),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

// Architecture-neutral secondaryText (expression body so CI strip regex does not remove it)
Color secondaryText(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white60
        : Colors.black54;

Color mutedText(BuildContext context) => secondaryText(context);

Color strongText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : Colors.black87;
}

Color subtleIcon(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white54
      : Colors.black45;
}
