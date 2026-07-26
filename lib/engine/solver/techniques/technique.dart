import '../candidate_grid.dart';

class SolveStep {
  final String technique;
  final int cellIndex;
  final int digit;
  final String explanation;

  const SolveStep({
    required this.technique,
    required this.cellIndex,
    required this.digit,
    required this.explanation,
  });
}

abstract class Technique {
  String get name;
  int get weight;

  /// Applies this technique once if possible, appending a [SolveStep] to
  /// [log] and returning true. Returns false with no side effects if the
  /// technique doesn't currently apply anywhere on the board.
  bool tryApply(CandidateGrid grid, List<SolveStep> log);
}
