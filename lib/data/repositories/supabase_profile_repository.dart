import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  final sb.SupabaseClient _client;

  SupabaseProfileRepository(this._client);

  static const _table = 'profiles';

  /// Postgres unique-violation. The insert races against other clients, so
  /// this is the authoritative "taken" signal -- not the availability check.
  static const _uniqueViolation = '23505';

  @override
  Future<Profile?> myProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final row = await _client
        .from(_table)
        .select('id, username')
        .eq('id', uid)
        .maybeSingle();

    if (row == null) return null;
    return Profile(id: row['id'] as String, username: row['username'] as String);
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final row = await _client
        .from(_table)
        .select('id')
        .eq('username', username.trim())
        .maybeSingle();
    return row == null;
  }

  @override
  Future<Profile> claimUsername(String username) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Cannot claim a username while signed out.');
    }

    try {
      final row = await _client
          .from(_table)
          .upsert({'id': uid, 'username': username.trim()})
          .select('id, username')
          .single();
      return Profile(
        id: row['id'] as String,
        username: row['username'] as String,
      );
    } on sb.PostgrestException catch (e) {
      if (e.code == _uniqueViolation) throw const UsernameTakenException();
      rethrow;
    }
  }
}
