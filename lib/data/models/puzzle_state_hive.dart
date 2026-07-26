import 'package:hive/hive.dart';

/// In-progress board for one difficulty tier. Hand-written adapter (no
/// hive_generator -- it pins an old `analyzer` that conflicts with
/// flutter_riverpod's).
class PuzzleStateHive {
  final String difficulty;
  final int seed;
  final List<int> givens;
  final List<int> solution;
  final List<int> userValues;
  final List<int> notes;
  final int elapsedSeconds;
  final int mistakes;
  final int hintsUsed;

  PuzzleStateHive({
    required this.difficulty,
    required this.seed,
    required this.givens,
    required this.solution,
    required this.userValues,
    required this.notes,
    required this.elapsedSeconds,
    required this.mistakes,
    required this.hintsUsed,
  });
}

class PuzzleStateHiveAdapter extends TypeAdapter<PuzzleStateHive> {
  @override
  final int typeId = 0;

  @override
  PuzzleStateHive read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return PuzzleStateHive(
      difficulty: fields[0] as String,
      seed: fields[1] as int,
      givens: (fields[2] as List).cast<int>(),
      solution: (fields[3] as List).cast<int>(),
      userValues: (fields[4] as List).cast<int>(),
      notes: (fields[5] as List).cast<int>(),
      elapsedSeconds: fields[6] as int,
      mistakes: fields[7] as int,
      hintsUsed: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PuzzleStateHive obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.difficulty)
      ..writeByte(1)
      ..write(obj.seed)
      ..writeByte(2)
      ..write(obj.givens)
      ..writeByte(3)
      ..write(obj.solution)
      ..writeByte(4)
      ..write(obj.userValues)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.elapsedSeconds)
      ..writeByte(7)
      ..write(obj.mistakes)
      ..writeByte(8)
      ..write(obj.hintsUsed);
  }
}
