import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../engine/models/difficulty.dart';
import 'solves_repository.dart';

class SupabaseSolvesRepository implements SolvesRepository {
  final sb.SupabaseClient _client;

  SupabaseSolvesRepository(this._client);

  static const _table = 'solves';

  @override
  Future<void> recordSolve({
    required Difficulty difficulty,
    required int seed,
    required int elapsedMs,
    required int mistakes,
    required int hintsUsed,
  }) async {
    final uid = _client.auth.currentUser?.id;
    // Signed-out players still get local stats; there's just nothing to rank.
    if (uid == null) return;

    await _client.from(_table).upsert(
      {
        'user_id': uid,
        'tier': difficulty.name,
        'seed': seed,
        'elapsed_ms': elapsedMs,
        'mistakes': mistakes,
        'hints_used': hintsUsed,
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      },
      // Matches the one_solve_per_puzzle constraint, so a replay updates the
      // existing row instead of erroring on the unique index.
      onConflict: 'user_id,tier,seed',
    );
  }

  @override
  Future<List<LeaderboardEntry>> leaderboard({
    required Difficulty difficulty,
    required int seed,
    int limit = 50,
  }) async {
    final rows = await _client
        .from(_table)
        .select('user_id, elapsed_ms, mistakes, hints_used, completed_at')
        .eq('tier', difficulty.name)
        .eq('seed', seed)
        .order('elapsed_ms', ascending: true)
        .limit(limit);

    final solves = rows as List;
    if (solves.isEmpty) return const [];

    // Resolve names in a second query rather than a PostgREST embed:
    // solves.user_id and profiles.id both point at auth.users independently,
    // and PostgREST can't traverse that (PGRST200). Adding a direct FK would
    // also mean a solve couldn't exist before its owner picked a username.
    // The row count here is bounded by `limit`, so this stays one small
    // extra round trip.
    final ids = solves.map((r) => r['user_id'] as String).toSet().toList();
    final profileRows = await _client
        .from('profiles')
        .select('id, username')
        .inFilter('id', ids);

    final names = {
      for (final p in profileRows as List)
        p['id'] as String: p['username'] as String,
    };

    return solves
        .map((r) {
          final id = r['user_id'] as String;
          final name = names[id];
          // Signed in but no username yet: nothing to display them as, so
          // they simply don't appear on the board.
          if (name == null) return null;
          return LeaderboardEntry(
            userId: id,
            username: name,
            elapsedMs: r['elapsed_ms'] as int,
            mistakes: r['mistakes'] as int? ?? 0,
            hintsUsed: r['hints_used'] as int? ?? 0,
            completedAt: DateTime.parse(r['completed_at'] as String),
          );
        })
        .nonNulls
        .toList();
  }
}
