import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const bgPage = Color(0xFFF7F3EF);
  static const bgSoftPink = Color(0xFFFFF4F1);
  static const bgLavender = Color(0xFFEDE8E2);
  static const bgPeach = Color(0xFFFFE1D7);
  static const bgMint = Color(0xFFEAF3EE);
  static const bgBlue = Color(0xFFEFF3F6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFFCFAF7);
  static const primary = Color(0xFFC1122F);
  static const primaryHover = Color(0xFF941126);
  static const secondary = Color(0xFF1C1B1A);
  static const accentPeach = Color(0xFFE25535);
  static const accentMint = Color(0xFF276749);
  static const textPrimary = Color(0xFF1C1B1A);
  static const textSecondary = Color(0xFF69635F);
  static const borderSoft = Color(0xFFE3DDD6);
  static const success = Color(0xFF276749);
  static const successSoft = Color(0xFFE6F2EA);
  static const warning = Color(0xFFE25535);
  static const error = Color(0xFFB42318);
  static const darkPromo = Color(0xFF111111);
  static const onDark = Color(0xFFFFFFFF);
  static const errorSoft = Color(0xFFFEECEB);

  static const womanTheme = [bgSoftPink, bgLavender, bgPeach];
  static const manTheme = [bgBlue, bgMint, Color(0xFFF4E9DD)];
}

class AppRadii {
  const AppRadii._();

  static const button = 8.0;
  static const search = 8.0;
  static const card = 10.0;
  static const block = 12.0;
  static const pill = 999.0;
}

class AppLayout {
  const AppLayout._();

  static const maxContentWidth = 1360.0;

  static double contentMaxWidth(double viewportWidth) {
    if (viewportWidth >= 1440) return maxContentWidth;
    if (viewportWidth >= 1280) return 1200.0;
    if (viewportWidth >= 1024) return 1120.0;
    if (viewportWidth >= 992) return 960.0;
    if (viewportWidth >= 768) return 720.0;
    if (viewportWidth >= 576) return 540.0;

    return viewportWidth;
  }

  static double horizontalPadding(double viewportWidth) {
    if (viewportWidth >= 1280) return 48.0;
    if (viewportWidth >= 1024) return 32.0;
    if (viewportWidth >= 768) return 24.0;
    return 16.0;
  }

  static double containerSideInset(double viewportWidth) {
    final basePadding = horizontalPadding(viewportWidth);
    final contentWidth = contentMaxWidth(viewportWidth);
    if (viewportWidth <= contentWidth) {
      return basePadding;
    }

    return (viewportWidth - contentWidth) / 2;
  }
}

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> base = [
    BoxShadow(
      color: const Color(0xFF1C1B1A).withValues(alpha: 0.07),
      blurRadius: 18,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> hover = [
    BoxShadow(
      color: const Color(0xFF1C1B1A).withValues(alpha: 0.12),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> mobile = [
    BoxShadow(
      color: const Color(0xFF1C1B1A).withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}
