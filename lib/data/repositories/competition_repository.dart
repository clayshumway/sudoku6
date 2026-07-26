import '../../engine/models/difficulty.dart';

enum CompetitionStatus { lobby, active, complete }

class Competition {
  final String id;
  final String code;
  final String hostId;
  final Difficulty difficulty;
  final int rounds;
  final int currentRound;
  final CompetitionStatus status;

  const Competition({
    required this.id,
    required this.code,
    required this.hostId,
    required this.difficulty,
    required this.rounds,
    required this.currentRound,
    required this.status,
  });

  bool isHost(String? userId) => userId != null && userId == hostId;
  bool get inLobby => status == CompetitionStatus.lobby;
  bool get isComplete => status == CompetitionStatus.complete;
}

class CompetitionPlayer {
  final String userId;
  final String username;

  const CompetitionPlayer({required this.userId, required this.username});
}

/// A started round. Carries the seed, which only exists once the round has
/// begun -- that's what makes "no peeking before everyone joins" structural
/// rather than a UI convention.
class CompetitionRound {
  final int roundNumber;
  final int seed;
  final DateTime startedAt;

  const CompetitionRound({
    required this.roundNumber,
    required this.seed,
    required this.startedAt,
  });
}

class StandingsRow {
  final String userId;
  final String username;
  final int roundsPlayed;
  final int totalMs;
  final int totalMistakes;
  final int totalHints;

  const StandingsRow({
    required this.userId,
    required this.username,
    required this.roundsPlayed,
    required this.totalMs,
    required this.totalMistakes,
    required this.totalHints,
  });
}

class CompetitionException implements Exception {
  final String message;
  const CompetitionException(this.message);
  @override
  String toString() => message;
}

abstract class CompetitionRepository {
  /// Creates a competition and returns its share code.
  Future<String> create({required Difficulty difficulty, required int rounds});

  /// Joins by share code. Idempotent -- re-joining is not an error.
  Future<String> join(String code);

  Future<Competition?> byCode(String code);
  Future<Competition?> byId(String id);

  Future<List<CompetitionPlayer>> players(String competitionId);

  /// Host-only. Enforced server-side, including the two-player minimum.
  Future<int> startNextRound({
    required String competitionId,
    required int seed,
  });

  Future<CompetitionRound?> round({
    required String competitionId,
    required int roundNumber,
  });

  /// Submits a finished round. Returns the **server-computed** elapsed time:
  /// the client never supplies it, so a reported time can't be invented.
  Future<int> finishRound({
    required String competitionId,
    required int roundNumber,
    required int mistakes,
    required int hintsUsed,
  });

  Future<List<StandingsRow>> standings(String competitionId);

  /// Emits whenever the competition row or its players change, so a lobby
  /// updates as people arrive without polling.
  Stream<void> watch(String competitionId);
}
