enum AppThemeMode { system, light, dark }

class AppSettings {
  final AppThemeMode themeMode;
  final bool soundEnabled;
  final bool hapticsEnabled;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? soundEnabled,
    bool? hapticsEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
}

abstract class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}
