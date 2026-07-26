import 'package:supabase_flutter/supabase_flutter.dart' as sb;

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

  /// Pulls the wait time out of Supabase's rate-limit message, which reads
  /// "For security purposes, you can only request this after 36 seconds."
  /// There's no structured field for it, so the number has to be parsed;
  /// falls back to a conservative 60s if the wording ever changes.
  static int _retryAfterFrom(String message) {
    final m = RegExp(r'(\d+)\s*second').firstMatch(message);
    return int.tryParse(m?.group(1) ?? '') ?? 60;
  }

  @override
  Future<void> sendSignInCode(String email) async {
    try {
      // No emailRedirectTo: the template emails a {{ .Token }} code and
      // contains no link, so there is no redirect to configure and nothing
      // for a mail scanner to consume.
      await _client.auth.signInWithOtp(email: email.trim());
    } on sb.AuthApiException catch (e) {
      if (e.statusCode == '429' || e.code == 'over_email_send_rate_limit') {
        throw AuthRateLimited(_retryAfterFrom(e.message));
      }
      throw AuthException(e.message);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> verifySignInCode({
    required String email,
    required String code,
  }) async {
    try {
      await _client.auth.verifyOTP(
        email: email.trim(),
        token: code.trim(),
        type: sb.OtpType.email,
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
