/// The signed-in user, reduced to what the app actually needs.
///
/// Deliberately not Supabase's `User` type: keeping the provider's model out of
/// the state and UI layers is what makes swapping or self-hosting the backend a
/// one-class change.
class AuthUser {
  final String id;
  final String email;

  const AuthUser({required this.id, required this.email});
}

/// Raised for failures worth showing the user verbatim.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

abstract class AuthRepository {
  /// Current user, or null when signed out.
  AuthUser? get currentUser;

  /// Emits on sign-in, sign-out, and token refresh.
  Stream<AuthUser?> authStateChanges();

  /// Emails a one-time sign-in link. Creates the account on first use, so
  /// there is no separate sign-up path.
  Future<void> sendMagicLink(String email);

  Future<void> signOut();
}
