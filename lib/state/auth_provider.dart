import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../config/supabase_config.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/supabase_auth_repository.dart';
import '../data/repositories/supabase_profile_repository.dart';

/// Null when Supabase isn't configured, which is what keeps the app fully
/// playable offline: every social surface checks this and hides itself rather
/// than erroring.
final supabaseClientProvider = Provider<sb.SupabaseClient?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  return sb.Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseAuthRepository(client);
});

final profileRepositoryProvider = Provider<ProfileRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseProfileRepository(client);
});

/// Current user, refreshed on sign-in/sign-out/token refresh.
final authUserProvider = StreamProvider<AuthUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  if (repo == null) return Stream.value(null);
  return repo.authStateChanges();
});

final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authUserProvider).value != null;
});

/// The signed-in user's profile, or null if they haven't claimed a username.
/// Re-fetches whenever the auth user changes.
final myProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(authUserProvider).value;
  if (user == null) return null;
  final repo = ref.watch(profileRepositoryProvider);
  if (repo == null) return null;
  return repo.myProfile();
});

/// Whether the app should be showing account-related UI at all.
final authAvailableProvider = Provider<bool>((ref) {
  return ref.watch(authRepositoryProvider) != null;
});

enum MagicLinkStatus { idle, sending, sent, error }

class MagicLinkState {
  final MagicLinkStatus status;
  final String? message;

  const MagicLinkState({this.status = MagicLinkStatus.idle, this.message});
}

class MagicLinkController extends Notifier<MagicLinkState> {
  @override
  MagicLinkState build() => const MagicLinkState();

  Future<void> send(String email) async {
    final repo = ref.read(authRepositoryProvider);
    if (repo == null) return;

    state = const MagicLinkState(status: MagicLinkStatus.sending);
    try {
      await repo.sendMagicLink(email);
      state = const MagicLinkState(status: MagicLinkStatus.sent);
    } on AuthException catch (e) {
      state = MagicLinkState(status: MagicLinkStatus.error, message: e.message);
    } catch (_) {
      state = const MagicLinkState(
        status: MagicLinkStatus.error,
        message: 'Could not send the link. Check the address and try again.',
      );
    }
  }

  void reset() => state = const MagicLinkState();
}

final magicLinkControllerProvider =
    NotifierProvider<MagicLinkController, MagicLinkState>(
        MagicLinkController.new);
