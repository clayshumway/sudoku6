import 'package:hive/hive.dart';

class SettingsHive {
  final String themeMode;
  final bool soundEnabled;
  final bool hapticsEnabled;

  SettingsHive({
    required this.themeMode,
    required this.soundEnabled,
    required this.hapticsEnabled,
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
    );
  }

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
