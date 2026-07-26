import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repositories/settings_repository.dart';
import 'state/settings_provider.dart';
import 'ui/routing/app_router.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/palette.dart';

class SudokuApp extends ConsumerWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final scheme = AppPalettes.byId(settings.paletteId);
    return MaterialApp.router(
      title: 'Sudoku 6',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(scheme),
      darkTheme: AppTheme.dark(scheme),
      themeMode: _toThemeMode(settings.themeMode),
      routerConfig: ref.watch(appRouterProvider),
    );
  }

  ThemeMode _toThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
