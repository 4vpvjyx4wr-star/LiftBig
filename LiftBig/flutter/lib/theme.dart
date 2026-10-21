import 'package:flutter/material.dart';

abstract final class LiftBigColors {
  static const background = Color(0xFF0A0F1E);
  static const card = Color(0xFF111827);
  static const cardInner = Color(0xFF0D1526);
  static const border = Color(0xFF1E2A45);
  static const primary = Color(0xFFF4501E);
  static const foreground = Color(0xFFF0F4FF);
  static const muted = Color(0xFF4A5A7A);
  static const success = Color(0xFF4ADE80);
}

ThemeData buildLiftBigTheme() {
  const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
    side: BorderSide(color: LiftBigColors.border),
  );
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: LiftBigColors.background,
    colorScheme: const ColorScheme.dark(
      primary: LiftBigColors.primary,
      onPrimary: Colors.white,
      surface: LiftBigColors.card,
      onSurface: LiftBigColors.foreground,
      secondary: LiftBigColors.primary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: LiftBigColors.background,
      foregroundColor: LiftBigColors.foreground,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(color: LiftBigColors.card, shape: shape),
    dividerColor: LiftBigColors.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LiftBigColors.cardInner,
      labelStyle: const TextStyle(color: LiftBigColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LiftBigColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LiftBigColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LiftBigColors.primary),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LiftBigColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LiftBigColors.foreground,
        side: const BorderSide(color: LiftBigColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: LiftBigColors.card,
      contentTextStyle: TextStyle(color: LiftBigColors.foreground),
    ),
  );
}
