import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const bgPage = Color(0xFFFFF8FB);
  static const bgSoftPink = Color(0xFFFBE8EF);
  static const bgLavender = Color(0xFFEEE8FA);
  static const bgPeach = Color(0xFFFCE8DC);
  static const bgMint = Color(0xFFE4F3EC);
  static const bgBlue = Color(0xFFE8F1FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFFFFDFE);
  static const primary = Color(0xFFC987A3);
  static const primaryHover = Color(0xFFB46F8D);
  static const secondary = Color(0xFFA99AD1);
  static const accentPeach = Color(0xFFE9A98C);
  static const accentMint = Color(0xFF8FBFA8);
  static const textPrimary = Color(0xFF3D3440);
  static const textSecondary = Color(0xFF756B78);
  static const borderSoft = Color(0xFFEADDE4);
  static const success = Color(0xFF7FAF98);
  static const warning = Color(0xFFE7BB75);
  static const error = Color(0xFFC97882);

  static const womanTheme = [bgSoftPink, bgLavender, bgPeach];
  static const manTheme = [bgBlue, bgMint, Color(0xFFF4E9DD)];
}

class AppRadii {
  const AppRadii._();

  static const button = 12.0;
  static const search = 14.0;
  static const card = 16.0;
  static const block = 20.0;
  static const pill = 999.0;
}

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> base = [
    BoxShadow(
      color: const Color(0xFF694C64).withValues(alpha: 0.10),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: const Color(0xFF694C64).withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> hover = [
    BoxShadow(
      color: const Color(0xFF694C64).withValues(alpha: 0.16),
      blurRadius: 40,
      offset: const Offset(0, 18),
    ),
    BoxShadow(
      color: const Color(0xFF694C64).withValues(alpha: 0.08),
      blurRadius: 14,
      offset: const Offset(0, 5),
    ),
  ];
}
