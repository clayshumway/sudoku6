import '../../engine/models/difficulty.dart';

enum CompetitionStatus { lobby, active, complete }

/// How rounds are paced.
///
/// [sync] is the original: the host starts each round and everyone plays it at
/// the same moment, against one shared clock. [async] lets each player take
/// rounds whenever they like, against their own clock, with standings showing
/// each player's total through their own last completed round.
enum CompetitionMode { sync, async }

class Competition {
  final String id;
  final String code;
  final String hostId;
  final Difficulty difficulty;
  final int rounds;
  final int currentRound;
  final CompetitionStatus status;
  final CompetitionMode mode;
  final DateTime createdAt;

  /// Set once someone starts a rematch of this (finished) competition.
  /// Anyone still looking at this one can follow it across.
  final String? rematchId;

  const Competition({
    required this.id,
    required this.code,
    required this.hostId,
    required this.difficulty,
    required this.rounds,
    required this.currentRound,
    required this.status,
    required this.createdAt,
    this.mode = CompetitionMode.sync,
    this.rematchId,
  });

  bool isHost(String? userId) => userId != null && userId == hostId;
  bool get inLobby => status == CompetitionStatus.lobby;
  bool get isComplete => status == CompetitionStatus.complete;
  bool get isAsync => mode == CompetitionMode.async;
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
  Future<String> create({
    required Difficulty difficulty,
    required int rounds,
    CompetitionMode mode = CompetitionMode.async,
  });

  /// Joins by share code. Idempotent -- re-joining is not an error.
  Future<String> join(String code);

  Future<Competition?> byCode(String code);
  Future<Competition?> byId(String id);

  /// The newest competition in [competitionId]'s rematch chain, or null when
  /// no rematch has been started.
  ///
  /// Server-side walk rather than repeated [byId] calls: reads are restricted
  /// to players, and the whole point of this lookup is the player who is *not*
  /// in the rematch -- they'd see nothing walking the chain themselves.
  Future<Competition?> chainTip(String competitionId);

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

  /// Async only. Opens [roundNumber] for the caller and returns its seed,
  /// stamping their personal start clock server-side.
  ///
  /// Rounds must be taken in order, which the server enforces -- the seed for
  /// a round you haven't reached is not readable, so this is the only way to
  /// obtain one.
  Future<int> startRound({
    required String competitionId,
    required int roundNumber,
  });

  /// Async only, host only. Ends a competition that still has unplayed rounds
  /// -- the way out when someone joins and never plays.
  Future<void> closeCompetition(String competitionId);

  /// Round numbers the caller has already finished, used to work out which
  /// round they're on. Async has no shared round pointer to read.
  Future<Set<int>> myFinishedRounds(String competitionId);

  /// Submits a finished round. Returns the **server-computed** elapsed time:
  /// the client never supplies it, so a reported time can't be invented.
  Future<int> finishRound({
    required String competitionId,
    required int roundNumber,
    required int mistakes,
    required int hintsUsed,
  });

  Future<List<StandingsRow>> standings(String competitionId);

  /// User ids with a submitted result for one round. Authoritative, unlike
  /// inferring it from rounds-played counts, which breaks the moment someone
  /// skips a round.
  Future<Set<String>> roundFinishers({
    required String competitionId,
    required int roundNumber,
  });

  /// Marks the caller ready for the round after the current one. Returns that
  /// round number.
  Future<int> markReady(String competitionId);

  /// User ids who have pressed Ready for [roundNumber].
  Future<Set<String>> readyPlayers({
    required String competitionId,
    required int roundNumber,
  });

  /// Starts (or returns the existing) rematch of a finished competition and
  /// returns its share code. Any player of the original can trigger it; a
  /// second press converges on the first rematch instead of forking.
  Future<String> rematch(String competitionId);

  /// Competitions the signed-in user has played or is playing, newest first.
  Future<List<Competition>> myCompetitions({int limit = 20});

  /// Fires the "rematch started" email to previous players who haven't
  /// joined yet. Best-effort: failures are swallowed, because every
  /// user-visible signal (banner, history, the old link) works without it.
  Future<void> notifyRematch(String rematchCompetitionId);

  /// Emits whenever the competition or its players/results/readiness change.
  /// Implementations must not rely solely on realtime delivery -- see the
  /// Supabase implementation for why.
  Stream<void> watch(String competitionId);
}
