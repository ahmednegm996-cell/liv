import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // accents
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
      case 'teal':
        return teal;
      case 'blue':
        return blue;
      case 'pink':
        return pink;
      case 'orange':
        return orange;
      case 'green':
        return green;
      case 'indigo':
        return indigo;
      default:
        return purple;
    }
  }
}

class AppTheme {
  static ThemeData light({required String accent, bool danger = false}) {
    final primary = AppColors.accentFrom(accent);
    final bg = const Color(0xFFF8F7FC);
    final card = Colors.white;
    final surface = const Color(0xFFF1F0F7);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        surface: surface,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: primary.withOpacity(0.08),
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),
      cardColor: card,
      dividerColor: Colors.black.withOpacity(0.06),
    );
  }

  static ThemeData dark({required String accent, bool danger = false}) {
    final primary = AppColors.accentFrom(accent);
    final bg = const Color(0xFF0F0F14);
    final card = const Color(0xFF1A1A22);
    final surface = const Color(0xFF16161D);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        surface: surface,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: primary.withOpacity(0.12),
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),
      cardColor: card,
      dividerColor: Colors.white.withOpacity(0.08),
    );
  }
}

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

class Gaps {
  static const h4 = SizedBox(height: 4);
  static const h8 = SizedBox(height: 8);
  static const h10 = SizedBox(height: 10);
  static const h12 = SizedBox(height: 12);
  static const h16 = SizedBox(height: 16);
  static const h18 = SizedBox(height: 18);
  static const h20 = SizedBox(height: 20);
  static const h24 = SizedBox(height: 24);
  static const h32 = SizedBox(height: 32);
  static const w8 = SizedBox(width: 8);
  static const w12 = SizedBox(width: 12);
}
