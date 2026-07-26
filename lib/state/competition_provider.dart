import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/competition_repository.dart';
import '../data/repositories/supabase_competition_repository.dart';
import '../engine/models/difficulty.dart';
import 'auth_provider.dart';

final competitionRepositoryProvider = Provider<CompetitionRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseCompetitionRepository(client);
});

/// Everything a competition screen needs, fetched together so the lobby,
/// standings and round state can never disagree with each other.
class CompetitionView {
  final Competition competition;
  final List<CompetitionPlayer> players;
  final List<StandingsRow> standings;

  /// The in-progress round, or null while in the lobby.
  final CompetitionRound? round;

  /// User ids who have already finished [round].
  final Set<String> finishedCurrentRound;

  /// User ids who have pressed Ready for the round after the current one.
  final Set<String> readyNextRound;

  /// The newest competition in this one's rematch chain, if any. Drives the
  /// "a rematch has started" banner -- which must only appear while that
  /// rematch is actually joinable. A player looking at an old competition
  /// whose rematch already ran to completion gets no banner, just the normal
  /// Rematch button (which extends the chain from its tip).
  final Competition? rematchTip;

  const CompetitionView({
    required this.competition,
    required this.players,
    required this.standings,
    required this.round,
    required this.finishedCurrentRound,
    required this.readyNextRound,
    required this.rematchTip,
  });

  /// True only while there is an ongoing rematch worth pointing people at.
  bool get rematchJoinable => rematchTip != null && !rematchTip!.isComplete;

  bool get canStart => players.length >= 2;
  bool hasFinishedCurrent(String? userId) =>
      userId != null && finishedCurrentRound.contains(userId);
  bool hasMarkedReady(String? userId) =>
      userId != null && readyNextRound.contains(userId);

  /// Whether every player *except the host* is ready for the next round.
  /// The host's Start press counts as their own ready, so they aren't made
  /// to tap two buttons.
  bool allOthersReady(String hostId) => players
      .where((p) => p.userId != hostId)
      .every((p) => readyNextRound.contains(p.userId));
}

/// Live view of one competition. Re-reads on every realtime notification
/// rather than trying to patch state incrementally -- the payloads are tiny
/// and a full re-read can't drift out of sync.
final competitionViewProvider =
    StreamProvider.autoDispose.family<CompetitionView, String>((ref, id) async* {
  final repo = ref.watch(competitionRepositoryProvider);
  if (repo == null) return;

  Future<CompetitionView?> load() async {
    final competition = await repo.byId(id);
    if (competition == null) return null;

    final players = await repo.players(id);
    final standings = await repo.standings(id);
    final round = competition.currentRound > 0
        ? await repo.round(
            competitionId: id, roundNumber: competition.currentRound)
        : null;

    // Asked for directly rather than inferred from rounds-played counts:
    // the count proxy miscounts anyone who skipped an earlier round.
    //
    // Both of these are auxiliary: they refine the view but the screen is
    // fully usable without them. They degrade to empty rather than throw --
    // a failing query here once took the whole competition screen down with
    // "couldn't load" when a migration hadn't been applied yet.
    var finished = const <String>{};
    if (competition.currentRound > 0) {
      try {
        finished = await repo.roundFinishers(
            competitionId: id, roundNumber: competition.currentRound);
      } catch (_) {}
    }

    final hasNextRound = competition.currentRound > 0 &&
        competition.currentRound < competition.rounds &&
        !competition.isComplete;
    var ready = const <String>{};
    if (hasNextRound) {
      try {
        ready = await repo.readyPlayers(
            competitionId: id, roundNumber: competition.currentRound + 1);
      } catch (_) {}
    }

    // Follow the rematch chain to its newest member (bounded), degrading to
    // "no banner" on any failure -- same auxiliary-data rule as above.
    Competition? rematchTip;
    if (competition.rematchId != null) {
      try {
        var tip = await repo.byId(competition.rematchId!);
        var hops = 0;
        while (tip != null && tip.rematchId != null && hops < 20) {
          tip = await repo.byId(tip.rematchId!);
          hops++;
        }
        rematchTip = tip;
      } catch (_) {}
    }

    return CompetitionView(
      competition: competition,
      players: players,
      standings: standings,
      round: round,
      finishedCurrentRound: finished,
      readyNextRound: ready,
      rematchTip: rematchTip,
    );
  }

  final first = await load();
  if (first != null) yield first;

  await for (final _ in repo.watch(id)) {
    final next = await load();
    if (next != null) yield next;
  }
});

/// The signed-in user's competition history, newest first.
final myCompetitionsProvider =
    FutureProvider.autoDispose<List<Competition>>((ref) async {
  final repo = ref.watch(competitionRepositoryProvider);
  if (repo == null) return const [];
  return repo.myCompetitions();
});

enum CompeteAction { idle, working }

class CompeteState {
  final CompeteAction action;
  final String? error;

  /// Set once a create/join succeeds, so the screen can navigate.
  final String? competitionId;

  const CompeteState({
    this.action = CompeteAction.idle,
    this.error,
    this.competitionId,
  });

  bool get busy => action == CompeteAction.working;
}

class CompeteController extends Notifier<CompeteState> {
  @override
  CompeteState build() => const CompeteState();

  Future<void> create({
    required Difficulty difficulty,
    required int rounds,
  }) async {
    final repo = ref.read(competitionRepositoryProvider);
    if (repo == null) return;

    state = const CompeteState(action: CompeteAction.working);
    try {
      final code = await repo.create(difficulty: difficulty, rounds: rounds);
      final competition = await repo.byCode(code);
      state = CompeteState(competitionId: competition?.id);
    } on CompetitionException catch (e) {
      state = CompeteState(error: e.message);
    } catch (_) {
      state = const CompeteState(error: 'Could not create the competition.');
    }
  }

  Future<void> join(String code) async {
    final repo = ref.read(competitionRepositoryProvider);
    if (repo == null) return;

    state = const CompeteState(action: CompeteAction.working);
    try {
      final id = await repo.join(code);
      state = CompeteState(competitionId: id);
    } on CompetitionException catch (e) {
      state = CompeteState(error: e.message);
    } catch (_) {
      state = const CompeteState(error: 'Could not join that competition.');
    }
  }

  void reset() => state = const CompeteState();
}

final competeControllerProvider =
    NotifierProvider<CompeteController, CompeteState>(CompeteController.new);
