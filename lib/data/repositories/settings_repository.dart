enum AppThemeMode { system, light, dark }

/// Single source of truth for the default color scheme. Lives in the data layer
/// so the Hive adapter can fall back to it without importing the UI layer.
const String kDefaultPaletteId = 'retro';

class AppSettings {
  final AppThemeMode themeMode;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final String paletteId;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.paletteId = kDefaultPaletteId,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? soundEnabled,
    bool? hapticsEnabled,
    String? paletteId,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      paletteId: paletteId ?? this.paletteId,
    );
  }
}

abstract class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}
