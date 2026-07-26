const int gridSize = 6;
const int boxRowSize = 2;
const int boxColSize = 3;
const int cellCount = gridSize * gridSize;
const int allDigitsMask = 0x3F;

int rowOf(int index) => index ~/ gridSize;
int colOf(int index) => index % gridSize;
int boxRowOf(int row) => row ~/ boxRowSize;
int boxColOf(int col) => col ~/ boxColSize;
int boxIndexOf(int row, int col) => boxRowOf(row) * 2 + boxColOf(col);
int boxOfIndex(int index) => boxIndexOf(rowOf(index), colOf(index));
int cellIndex(int row, int col) => row * gridSize + col;

int digitBit(int digit) => 1 << (digit - 1);

int popCount(int mask) {
  var count = 0;
  var m = mask;
  while (m != 0) {
    count += m & 1;
    m >>= 1;
  }
  return count;
}

List<int> digitsInMask(int mask) {
  final digits = <int>[];
  for (var d = 1; d <= 6; d++) {
    if (mask & digitBit(d) != 0) digits.add(d);
  }
  return digits;
}

List<int> peersOf(int index) {
  final row = rowOf(index);
  final col = colOf(index);
  final box = boxOfIndex(index);
  final peers = <int>{};
  for (var c = 0; c < gridSize; c++) {
    peers.add(cellIndex(row, c));
  }
  for (var r = 0; r < gridSize; r++) {
    peers.add(cellIndex(r, col));
  }
  for (var i = 0; i < cellCount; i++) {
    if (boxOfIndex(i) == box) peers.add(i);
  }
  peers.remove(index);
  return peers.toList(growable: false);
}

final List<List<int>> rowUnits = List.generate(
  gridSize,
  (row) => List.generate(gridSize, (col) => cellIndex(row, col)),
  growable: false,
);

final List<List<int>> colUnits = List.generate(
  gridSize,
  (col) => List.generate(gridSize, (row) => cellIndex(row, col)),
  growable: false,
);

final List<List<int>> boxUnits = List.generate(6, (box) {
  final cells = <int>[];
  for (var i = 0; i < cellCount; i++) {
    if (boxOfIndex(i) == box) cells.add(i);
  }
  return cells;
}, growable: false);

final List<List<int>> allUnits = [...rowUnits, ...colUnits, ...boxUnits];

/// Immutable-by-convention 6x6 board. `cells[i] == 0` means empty.
class Grid {
  final List<int> cells;

  Grid(this.cells) : assert(cells.length == cellCount);

  Grid.empty() : cells = List<int>.filled(cellCount, 0);

  Grid.copy(Grid other) : cells = List<int>.from(other.cells);

  int operator [](int index) => cells[index];
  int at(int row, int col) => cells[cellIndex(row, col)];

  bool get isComplete => cells.every((v) => v != 0);

  int get clueCount => cells.where((v) => v != 0).length;

  Grid clone() => Grid.copy(this);

  @override
  bool operator ==(Object other) {
    if (other is! Grid) return false;
    for (var i = 0; i < cellCount; i++) {
      if (cells[i] != other.cells[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(cells);
}
