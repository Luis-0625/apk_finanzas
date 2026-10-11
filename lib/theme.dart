import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF08080C);
  static const surface = Color(0xFF14141C);
  static const surfaceHigh = Color(0xFF1E1E2A);
  static const purple = Color(0xFF9B5CFF);
  static const emerald = Color(0xFF22E3A1);
  static const expense = Color(0xFFFF5D7A);
  static const textMuted = Color(0xFF8E8EA3);
}

ThemeData buildTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.purple,
      secondary: AppColors.emerald,
      surface: AppColors.surface,
      error: AppColors.expense,
    ),
    textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
