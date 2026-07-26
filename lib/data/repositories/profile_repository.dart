class Profile {
  final String id;
  final String username;

  const Profile({required this.id, required this.username});
}

class UsernameTakenException implements Exception {
  const UsernameTakenException();
  @override
  String toString() => 'That username is already taken.';
}

abstract class ProfileRepository {
  /// Null when the user is signed in but hasn't claimed a username yet.
  Future<Profile?> myProfile();

  /// Advisory only -- the unique index is the real guard. Two people can pass
  /// this check simultaneously and one will still lose the race, so callers
  /// must handle [UsernameTakenException] from [claimUsername] regardless.
  Future<bool> isUsernameAvailable(String username);

  /// Throws [UsernameTakenException] if the name was claimed first.
  Future<Profile> claimUsername(String username);
}

/// Shared client-side rules, mirroring the CHECK constraints in
/// `supabase/migrations/0001_profiles.sql`. Returns null when valid.
String? validateUsername(String value) {
  final v = value.trim();
  if (v.length < 3) return 'At least 3 characters.';
  if (v.length > 20) return 'At most 20 characters.';
  if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(v)) {
    return 'Letters, numbers and underscores only.';
  }
  return null;
}
