import 'package:hive/hive.dart';

import '../repositories/settings_repository.dart';

class SettingsHive {
  final String themeMode;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final String paletteId;

  SettingsHive({
    required this.themeMode,
    required this.soundEnabled,
    required this.hapticsEnabled,
    required this.paletteId,
  });
}

class SettingsHiveAdapter extends TypeAdapter<SettingsHive> {
  @override
  final int typeId = 2;

  @override
  SettingsHive read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsHive(
      themeMode: fields[0] as String,
      soundEnabled: fields[1] as bool,
      hapticsEnabled: fields[2] as bool,
      // Field 3 was added after v1 shipped. Records written by v1 only have
      // fields 0-2, so this must fall back rather than cast a null -- otherwise
      // existing players lose every saved setting on upgrade.
      paletteId: fields[3] as String? ?? kDefaultPaletteId,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(1)
      ..write(obj.soundEnabled)
      ..writeByte(2)
      ..write(obj.hapticsEnabled)
      ..writeByte(3)
      ..write(obj.paletteId);
  }
}
