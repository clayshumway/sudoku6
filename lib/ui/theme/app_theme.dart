import 'package:flutter/material.dart';

import 'palette.dart';

class AppTheme {
  AppTheme._();

  /// Builds a [ThemeData] from a [Palette], attaching the palette itself as a
  /// [ThemeExtension] so widgets can read exact game colors (cell fills, grid
  /// lines) that don't map onto Material's [ColorScheme].
  static ThemeData from(Palette palette, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: brightness,
    ).copyWith(
      primary: palette.primary,
      surface: palette.surface,
      error: palette.errorText,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.givenText,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(backgroundColor: palette.surface),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: palette.surface),
      cardTheme: CardThemeData(color: palette.surface),
      extensions: [PaletteExtension(palette)],
    );
  }

  static ThemeData light(PaletteScheme s) =>
      from(s.light, Brightness.light);

  static ThemeData dark(PaletteScheme s) => from(s.dark, Brightness.dark);
}
