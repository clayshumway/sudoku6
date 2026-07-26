import 'package:hive/hive.dart';

class StatsEntryHive {
  final String difficulty;
  final int seed;
  final int elapsedSeconds;
  final int mistakes;
  final int hintsUsed;
  final int completedAtMillis;

  StatsEntryHive({
    required this.difficulty,
    required this.seed,
    required this.elapsedSeconds,
    required this.mistakes,
    required this.hintsUsed,
    required this.completedAtMillis,
  });
}

class StatsEntryHiveAdapter extends TypeAdapter<StatsEntryHive> {
  @override
  final int typeId = 1;

  @override
  StatsEntryHive read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return StatsEntryHive(
      difficulty: fields[0] as String,
      seed: fields[1] as int,
      elapsedSeconds: fields[2] as int,
      mistakes: fields[3] as int,
      hintsUsed: fields[4] as int,
      completedAtMillis: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StatsEntryHive obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.difficulty)
      ..writeByte(1)
      ..write(obj.seed)
      ..writeByte(2)
      ..write(obj.elapsedSeconds)
      ..writeByte(3)
      ..write(obj.mistakes)
      ..writeByte(4)
      ..write(obj.hintsUsed)
      ..writeByte(5)
      ..write(obj.completedAtMillis);
  }
}
