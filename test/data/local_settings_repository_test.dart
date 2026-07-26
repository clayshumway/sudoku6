import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sudoku6/data/hive_boxes.dart';
import 'package:sudoku6/data/models/settings_hive.dart';
import 'package:sudoku6/data/repositories/local_settings_repository.dart';
import 'package:sudoku6/data/repositories/settings_repository.dart';

/// Mimics the v1 adapter, which wrote only fields 0-2 (no paletteId).
/// Used to prove that settings saved before the color-scheme feature shipped
/// still load correctly instead of throwing or resetting.
class _V1SettingsHiveAdapter extends TypeAdapter<SettingsHive> {
  @override
  final int typeId = 2;

  @override
  SettingsHive read(BinaryReader reader) =>
      throw UnimplementedError('write-only fixture');

  @override
  void write(BinaryWriter writer, SettingsHive obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(1)
      ..write(obj.soundEnabled)
      ..writeByte(2)
      ..write(obj.hapticsEnabled);
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sudoku6_settings_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('round-trips the selected palette', () async {
    Hive.registerAdapter(SettingsHiveAdapter(), override: true);
    await Hive.openBox<SettingsHive>(HiveBoxes.settings);
    final repo = LocalSettingsRepository();

    await repo.save(const AppSettings(
      themeMode: AppThemeMode.dark,
      soundEnabled: false,
      hapticsEnabled: true,
      paletteId: 'apocalyptic',
    ));

    final loaded = await repo.load();
    expect(loaded.paletteId, 'apocalyptic');
    expect(loaded.themeMode, AppThemeMode.dark);
    expect(loaded.soundEnabled, isFalse);
    expect(loaded.hapticsEnabled, isTrue);
  });

  test('defaults to the retro palette when nothing is saved', () async {
    Hive.registerAdapter(SettingsHiveAdapter(), override: true);
    await Hive.openBox<SettingsHive>(HiveBoxes.settings);

    final loaded = await LocalSettingsRepository().load();
    expect(loaded.paletteId, kDefaultPaletteId);
  });

  test('reads v1 records (no paletteId field) without losing other settings',
      () async {
    // Write with the old 3-field layout...
    Hive.registerAdapter(_V1SettingsHiveAdapter(), override: true);
    var box = await Hive.openBox<SettingsHive>(HiveBoxes.settings);
    await box.put(
      'settings',
      SettingsHive(
        themeMode: 'light',
        soundEnabled: false,
        hapticsEnabled: false,
        paletteId: 'ignored-by-v1-adapter',
      ),
    );
    await Hive.close();

    // ...then read it back with the current adapter.
    Hive.init(tempDir.path);
    Hive.registerAdapter(SettingsHiveAdapter(), override: true);
    box = await Hive.openBox<SettingsHive>(HiveBoxes.settings);

    final loaded = await LocalSettingsRepository().load();
    expect(loaded.paletteId, kDefaultPaletteId,
        reason: 'missing field should fall back, not crash');
    expect(loaded.themeMode, AppThemeMode.light);
    expect(loaded.soundEnabled, isFalse);
    expect(loaded.hapticsEnabled, isFalse);
  });
}
