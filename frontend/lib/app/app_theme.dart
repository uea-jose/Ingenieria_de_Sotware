import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_design_tokens.dart';

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final bodyTextTheme = GoogleFonts.nunitoTextTheme(base.textTheme);
  final titleTextTheme = GoogleFonts.dmSerifDisplayTextTheme(base.textTheme);

  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.bgPage,
    cardColor: AppColors.surface,
    dividerColor: AppColors.borderSoft,
    canvasColor: AppColors.bgPage,
    shadowColor: const Color(0xFF694C64).withValues(alpha: 0.10),
    textTheme: bodyTextTheme.copyWith(
      displayLarge: titleTextTheme.displayLarge?.copyWith(
        fontSize: 56,
        fontWeight: FontWeight.w500,
        height: 0.98,
        color: AppColors.textPrimary,
      ),
      displayMedium: titleTextTheme.displayMedium?.copyWith(
        fontSize: 42,
        fontWeight: FontWeight.w500,
        height: 1.02,
        color: AppColors.textPrimary,
      ),
      headlineLarge: titleTextTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      headlineMedium: titleTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      headlineSmall: titleTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      titleLarge: bodyTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
      ),
      titleMedium: bodyTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      bodyLarge: bodyTextTheme.bodyLarge?.copyWith(
        color: AppColors.textSecondary,
        height: 1.55,
      ),
      bodyMedium: bodyTextTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      bodySmall: bodyTextTheme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
        height: 1.45,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceSoft,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.search),
        borderSide: const BorderSide(color: AppColors.borderSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.search),
        borderSide: const BorderSide(color: AppColors.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.search),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.borderSoft),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryHover,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    ),
  );
}
