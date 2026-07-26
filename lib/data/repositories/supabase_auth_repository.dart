import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../config/supabase_config.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final sb.SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  AuthUser? _toAuthUser(sb.User? user) {
    if (user == null) return null;
    return AuthUser(id: user.id, email: user.email ?? '');
  }

  @override
  AuthUser? get currentUser => _toAuthUser(_client.auth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() =>
      _client.auth.onAuthStateChange.map((e) => _toAuthUser(e.session?.user));

  @override
  Future<void> sendMagicLink(String email) async {
    try {
      await _client.auth.signInWithOtp(
        email: email.trim(),
        // Web returns to the site origin; Android comes back through the
        // deep link registered in AndroidManifest.xml.
        emailRedirectTo:
            kIsWeb ? SupabaseConfig.webRedirect : SupabaseConfig.mobileRedirect,
      );
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }
}
