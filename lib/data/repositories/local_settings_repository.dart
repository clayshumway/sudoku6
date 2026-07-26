import 'package:hive/hive.dart';

import '../hive_boxes.dart';
import '../models/settings_hive.dart';
import 'settings_repository.dart';

class LocalSettingsRepository implements SettingsRepository {
  Box<SettingsHive> get _box => Hive.box<SettingsHive>(HiveBoxes.settings);
  static const _key = 'settings';

  @override
  Future<AppSettings> load() async {
    final hive = _box.get(_key);
    if (hive == null) return const AppSettings();
    return AppSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (m) => m.name == hive.themeMode,
        orElse: () => AppThemeMode.system,
      ),
      soundEnabled: hive.soundEnabled,
      hapticsEnabled: hive.hapticsEnabled,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _box.put(
      _key,
      SettingsHive(
        themeMode: settings.themeMode.name,
        soundEnabled: settings.soundEnabled,
        hapticsEnabled: settings.hapticsEnabled,
      ),
    );
  }
}
