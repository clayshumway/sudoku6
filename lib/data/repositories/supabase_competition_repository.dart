import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../engine/models/difficulty.dart';
import 'competition_repository.dart';

class SupabaseCompetitionRepository implements CompetitionRepository {
  final sb.SupabaseClient _client;

  SupabaseCompetitionRepository(this._client);

  Difficulty _tier(String name) => Difficulty.values.firstWhere(
        (d) => d.name == name,
        orElse: () => Difficulty.easy,
      );

  CompetitionStatus _status(String s) => switch (s) {
        'active' => CompetitionStatus.active,
        'complete' => CompetitionStatus.complete,
        _ => CompetitionStatus.lobby,
      };

  Competition _toCompetition(Map<String, dynamic> r) => Competition(
        id: r['id'] as String,
        code: r['code'] as String,
        hostId: r['host_id'] as String,
        difficulty: _tier(r['tier'] as String),
        rounds: r['rounds'] as int,
        currentRound: r['current_round'] as int,
        status: _status(r['status'] as String),
        // Absent until 0011; anything without the column is a sync
        // competition, which is exactly what the default gives.
        mode: r['mode'] == 'async'
            ? CompetitionMode.async
            : CompetitionMode.sync,
        createdAt: DateTime.parse(r['created_at'] as String),
        // Absent until migration 0008 has been applied; null-safe either way.
        rematchId: r['rematch_id'] as String?,
      );

  /// Postgres exceptions from our RPCs carry a human-written message
  /// ("need at least 2 players"), which is more useful to show than a
  /// generic failure.
  Never _rethrow(Object e) {
    if (e is sb.PostgrestException) throw CompetitionException(e.message);
    throw const CompetitionException('Something went wrong. Try again.');
  }

  @override
  Future<String> create({
    required Difficulty difficulty,
    required int rounds,
    CompetitionMode mode = CompetitionMode.async,
  }) async {
    try {
      final code = await _client.rpc('create_competition_mode', params: {
        'p_tier': difficulty.name,
        'p_rounds': rounds,
        'p_mode': mode.name,
      });
      return code as String;
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<String> join(String code) async {
    try {
      final id = await _client
          .rpc('join_competition', params: {'p_code': code.trim()});
      return id as String;
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<Competition?> byCode(String code) async {
    final r = await _client
        .from('competitions')
        .select()
        .eq('code', code.trim().toUpperCase())
        .maybeSingle();
    return r == null ? null : _toCompetition(r);
  }

  @override
  Future<Competition?> byId(String id) async {
    final r = await _client
        .from('competitions')
        .select()
        .eq('id', id)
        .maybeSingle();
    return r == null ? null : _toCompetition(r);
  }

  @override
  Future<Competition?> chainTip(String competitionId) async {
    final rows = await _client
        .rpc('competition_chain_tip', params: {'p_competition': competitionId});
    final list = rows as List;
    if (list.isEmpty) return null;
    return _toCompetition(list.first as Map<String, dynamic>);
  }

  @override
  Future<List<CompetitionPlayer>> players(String competitionId) async {
    final rows = await _client
        .from('competition_players')
        .select('user_id')
        .eq('competition_id', competitionId)
        .order('joined_at');

    final ids = (rows as List).map((r) => r['user_id'] as String).toList();
    if (ids.isEmpty) return const [];

    // Same two-query pattern as the leaderboard: no FK path from
    // competition_players to profiles for PostgREST to follow.
    final profiles = await _client
        .from('profiles')
        .select('id, username')
        .inFilter('id', ids);

    final names = {
      for (final p in profiles as List)
        p['id'] as String: p['username'] as String,
    };

    return ids
        .map((id) => names[id] == null
            ? null
            : CompetitionPlayer(userId: id, username: names[id]!))
        .nonNulls
        .toList();
  }

  @override
  Future<int> startNextRound({
    required String competitionId,
    required int seed,
  }) async {
    try {
      final n = await _client.rpc('start_next_round', params: {
        'p_competition': competitionId,
        'p_seed': seed,
      });
      return n as int;
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<CompetitionRound?> round({
    required String competitionId,
    required int roundNumber,
  }) async {
    final r = await _client
        .from('competition_rounds')
        .select()
        .eq('competition_id', competitionId)
        .eq('round_number', roundNumber)
        .maybeSingle();
    if (r == null) return null;
    return CompetitionRound(
      roundNumber: r['round_number'] as int,
      seed: (r['seed'] as num).toInt(),
      startedAt: DateTime.parse(r['started_at'] as String),
    );
  }

  @override
  Future<int> startRound({
    required String competitionId,
    required int roundNumber,
  }) async {
    try {
      final seed = await _client.rpc('start_round', params: {
        'p_competition': competitionId,
        'p_round': roundNumber,
      });
      return (seed as num).toInt();
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<void> pauseRound({
    required String competitionId,
    required int roundNumber,
  }) async {
    try {
      await _client.rpc('pause_round', params: {
        'p_competition': competitionId,
        'p_round': roundNumber,
      });
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<void> resumeRound({
    required String competitionId,
    required int roundNumber,
  }) async {
    try {
      await _client.rpc('resume_round', params: {
        'p_competition': competitionId,
        'p_round': roundNumber,
      });
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<void> closeCompetition(String competitionId) async {
    try {
      await _client
          .rpc('close_competition', params: {'p_competition': competitionId});
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<Set<int>> myFinishedRounds(String competitionId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const {};
    final rows = await _client
        .from('competition_results')
        .select('round_number')
        .eq('competition_id', competitionId)
        .eq('user_id', uid);
    return (rows as List)
        .map((r) => (r['round_number'] as num).toInt())
        .toSet();
  }

  @override
  Future<int> finishRound({
    required String competitionId,
    required int roundNumber,
    required int mistakes,
    required int hintsUsed,
  }) async {
    try {
      final ms = await _client.rpc('finish_round', params: {
        'p_competition': competitionId,
        'p_round': roundNumber,
        'p_mistakes': mistakes,
        'p_hints': hintsUsed,
      });
      return (ms as num).toInt();
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<List<StandingsRow>> standings(String competitionId) async {
    final rows = await _client
        .from('competition_standings')
        .select()
        .eq('competition_id', competitionId);

    final list = (rows as List)
        .map((r) => StandingsRow(
              userId: r['user_id'] as String,
              username: r['username'] as String,
              roundsPlayed: (r['rounds_played'] as num).toInt(),
              totalMs: (r['total_ms'] as num).toInt(),
              totalMistakes: (r['total_mistakes'] as num?)?.toInt() ?? 0,
              totalHints: (r['total_hints'] as num?)?.toInt() ?? 0,
            ))
        .toList();

    // Most rounds finished wins first; total time breaks the tie. Sorting on
    // time alone would rank someone who skipped rounds above someone who
    // played them all.
    list.sort((a, b) {
      final byRounds = b.roundsPlayed.compareTo(a.roundsPlayed);
      return byRounds != 0 ? byRounds : a.totalMs.compareTo(b.totalMs);
    });
    return list;
  }

  @override
  Future<Set<String>> roundFinishers({
    required String competitionId,
    required int roundNumber,
  }) async {
    final rows = await _client
        .from('competition_results')
        .select('user_id')
        .eq('competition_id', competitionId)
        .eq('round_number', roundNumber);
    return (rows as List).map((r) => r['user_id'] as String).toSet();
  }

  @override
  Future<int> markReady(String competitionId) async {
    try {
      final n = await _client
          .rpc('mark_ready', params: {'p_competition': competitionId});
      return (n as num).toInt();
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<Set<String>> readyPlayers({
    required String competitionId,
    required int roundNumber,
  }) async {
    final rows = await _client
        .from('competition_ready')
        .select('user_id')
        .eq('competition_id', competitionId)
        .eq('round_number', roundNumber);
    return (rows as List).map((r) => r['user_id'] as String).toSet();
  }

  @override
  Future<String> rematch(String competitionId) async {
    try {
      final code = await _client
          .rpc('rematch_competition', params: {'p_competition': competitionId});
      return code as String;
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<List<Competition>> myCompetitions({int limit = 20}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];

    final memberships = await _client
        .from('competition_players')
        .select('competition_id')
        .eq('user_id', uid);
    final ids = (memberships as List)
        .map((r) => r['competition_id'] as String)
        .toList();
    if (ids.isEmpty) return const [];

    final rows = await _client
        .from('competitions')
        .select()
        .inFilter('id', ids)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => _toCompetition(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> notifyRematch(String rematchCompetitionId) async {
    try {
      await _client.functions.invoke('rematch-notify',
          body: {'competition_id': rematchCompetitionId});
    } catch (_) {
      // Best-effort by contract: the in-app banner, history list and the old
      // invite link are the reliable signals. Email is a bonus.
    }
  }

  @override
  Stream<void> watch(String competitionId) {
    final controller = StreamController<void>.broadcast();
    Timer? poll;
    // Scoped to this competition only -- realtime connections are the first
    // Supabase limit that bites, so nothing subscribes app-wide.
    final channel = _client
        .channel('competition:$competitionId')
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.all,
          schema: 'public',
          table: 'competitions',
          filter: sb.PostgresChangeFilter(
            type: sb.PostgresChangeFilterType.eq,
            column: 'id',
            value: competitionId,
          ),
          callback: (_) => controller.add(null),
        )
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.all,
          schema: 'public',
          table: 'competition_players',
          filter: sb.PostgresChangeFilter(
            type: sb.PostgresChangeFilterType.eq,
            column: 'competition_id',
            value: competitionId,
          ),
          callback: (_) => controller.add(null),
        )
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.all,
          schema: 'public',
          table: 'competition_results',
          filter: sb.PostgresChangeFilter(
            type: sb.PostgresChangeFilterType.eq,
            column: 'competition_id',
            value: competitionId,
          ),
          callback: (_) => controller.add(null),
        )
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.all,
          schema: 'public',
          table: 'competition_ready',
          filter: sb.PostgresChangeFilter(
            type: sb.PostgresChangeFilterType.eq,
            column: 'competition_id',
            value: competitionId,
          ),
          callback: (_) => controller.add(null),
        )
        // Async: someone opening a round is the signal that they're playing,
        // and there's no shared round pointer to notice it any other way.
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.all,
          schema: 'public',
          table: 'competition_attempts',
          filter: sb.PostgresChangeFilter(
            type: sb.PostgresChangeFilterType.eq,
            column: 'competition_id',
            value: competitionId,
          ),
          callback: (_) => controller.add(null),
        );

    channel.subscribe();

    // Polling fallback. A postgres_changes subscription to a table that isn't
    // in the supabase_realtime publication -- or whose socket has silently
    // died -- connects fine and then delivers nothing, which is exactly how
    // the lobby froze in testing. Realtime makes updates instant; this makes
    // them *guaranteed* within a few seconds. It only runs while a
    // competition screen is actually being watched (autoDispose cancels it).
    controller.onListen = () {
      poll = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!controller.isClosed) controller.add(null);
      });
    };
    controller.onCancel = () {
      poll?.cancel();
      _client.removeChannel(channel);
    };
    return controller.stream;
  }
}
