// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── COLORS ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF2E7D32);      // Deep green (crops)
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);

  static const Color moneyIn = Color(0xFF2E7D32);      // Green = money received
  static const Color moneyOut = Color(0xFFC62828);     // Red = money paid
  static const Color bagColor = Color(0xFF1565C0);     // Blue = bags/bori
  static const Color creditColor = Color(0xFFE65100);  // Orange = credit/udhaar

  static const Color surface = Color(0xFFFAFAFA);
  static const Color cardBg = Colors.white;
  static const Color divider = Color(0xFFE0E0E0);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // ── TYPOGRAPHY ───────────────────────────────────────────────
  // Noto Sans is great for Devanagari (Hindi) + Latin
  static TextTheme get textTheme => TextTheme(
    displayLarge: GoogleFonts.notoSans(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
    titleLarge:   GoogleFonts.notoSans(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
    titleMedium:  GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
    titleSmall:   GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
    bodyLarge:    GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.normal, color: textPrimary),
    bodyMedium:   GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.normal, color: textPrimary),
    bodySmall:    GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.normal, color: textSecondary),
    labelLarge:   GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
  );

  // ── LIGHT THEME ──────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: surface,
    textTheme: textTheme,

    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.notoSans(
        fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
      ),
    ),

    // Large, easy-to-tap buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        textStyle: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: GoogleFonts.notoSans(fontSize: 16, color: textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),

cardTheme: CardThemeData(
      color: cardBg,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    dividerTheme: const DividerThemeData(color: divider, thickness: 1),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: primary,
      unselectedItemColor: textSecondary,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
  );
}

// ── HELPER EXTENSIONS ────────────────────────────────────────────────
extension BuildContextTheme on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}
