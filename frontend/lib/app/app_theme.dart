import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF145647),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFFAF8F4),
    useMaterial3: true,
    fontFamily: 'Arial',
  );
}
