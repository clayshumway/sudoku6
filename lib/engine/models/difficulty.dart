enum Difficulty { easy, medium, hard, expert, master }

class TierConfig {
  final Difficulty difficulty;
  final int minClues;
  final int maxClues;

  /// Highest technique weight this tier's puzzles are allowed to need.
  /// Clue count (which the generator digs down to first) is the primary
  /// difficulty signal; this is a ceiling, not a floor -- a puzzle that
  /// only needs naked singles is still valid for Easy, it doesn't need to
  /// *require* a harder technique to qualify.
  final int ceilingWeight;
  final int stars;

  const TierConfig({
    required this.difficulty,
    required this.minClues,
    required this.maxClues,
    required this.ceilingWeight,
    required this.stars,
  });
}

const Map<Difficulty, TierConfig> kTierConfigs = {
  Difficulty.easy: TierConfig(
    difficulty: Difficulty.easy,
    minClues: 22,
    maxClues: 26,
    ceilingWeight: 1,
    stars: 1,
  ),
  Difficulty.medium: TierConfig(
    difficulty: Difficulty.medium,
    minClues: 17,
    maxClues: 21,
    ceilingWeight: 3,
    stars: 2,
  ),
  Difficulty.hard: TierConfig(
    difficulty: Difficulty.hard,
    minClues: 13,
    maxClues: 16,
    ceilingWeight: 4,
    stars: 3,
  ),
  Difficulty.expert: TierConfig(
    difficulty: Difficulty.expert,
    minClues: 10,
    maxClues: 12,
    ceilingWeight: 5,
    stars: 4,
  ),
  Difficulty.master: TierConfig(
    difficulty: Difficulty.master,
    minClues: 8,
    maxClues: 9,
    ceilingWeight: 5,
    stars: 5,
  ),
};
