/// A single undoable board edit. Notes are stored as a bitmask (bit d-1 =
/// digit d pencilled in).
class Move {
  final int cellIndex;
  final int previousValue;
  final int newValue;
  final int previousNotes;
  final int newNotes;

  const Move({
    required this.cellIndex,
    required this.previousValue,
    required this.newValue,
    required this.previousNotes,
    required this.newNotes,
  });
}
