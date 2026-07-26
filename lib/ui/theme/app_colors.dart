import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF3D5AFE);
  static const primaryDark = Color(0xFF7C8CFF);

  static const lightBackground = Color(0xFFF7F8FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightGridLine = Color(0xFFE0E2E7);
  static const lightBoxLine = Color(0xFF2B2F38);
  static const lightGivenText = Color(0xFF1B1D23);
  static const lightUserText = Color(0xFF3D5AFE);
  static const lightSelectedCell = Color(0xFFDDE3FF);
  static const lightPeerCell = Color(0xFFF0F1F5);
  static const lightErrorText = Color(0xFFD8453B);
  static const lightErrorCell = Color(0xFFFDE7E5);

  static const darkBackground = Color(0xFF15161B);
  static const darkSurface = Color(0xFF1E2027);
  static const darkGridLine = Color(0xFF33353E);
  static const darkBoxLine = Color(0xFFB8BCC8);
  static const darkGivenText = Color(0xFFEDEEF2);
  static const darkUserText = Color(0xFF8C9CFF);
  static const darkSelectedCell = Color(0xFF33395C);
  static const darkPeerCell = Color(0xFF23252D);
  static const darkErrorText = Color(0xFFFF6B60);
  static const darkErrorCell = Color(0xFF3B2226);

  // Per-digit cell tint: 1=yellow, 2=red, 3=blue, 4=green, 5=purple, 6=orange.
  static const Map<int, Color> digitColors = {
    1: Color(0xFFFBC02D),
    2: Color(0xFFE53935),
    3: Color(0xFF1E88E5),
    4: Color(0xFF43A047),
    5: Color(0xFF8E24AA),
    6: Color(0xFFFB8C00),
  };

  static Color digitColor(int digit) => digitColors[digit] ?? lightSurface;
}
