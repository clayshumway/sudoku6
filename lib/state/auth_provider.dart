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

enum SignInStep {
  /// Collecting the email address.
  email,

  /// Sending the code.
  sending,

  /// Code emailed; waiting for the user to type it.
  codeSent,

  /// Verifying the entered code.
  verifying,
}

class SignInState {
  final SignInStep step;

  /// Retained after the code is sent -- `verifyOTP` needs the address again,
  /// and the UI shows it back to the user.
  final String email;
  final String? error;

  const SignInState({
    this.step = SignInStep.email,
    this.email = '',
    this.error,
  });

  SignInState copyWith({SignInStep? step, String? email, String? error}) {
    return SignInState(
      step: step ?? this.step,
      email: email ?? this.email,
      // Explicitly clearable: each transition should drop the previous error.
      error: error,
    );
  }

  bool get busy =>
      step == SignInStep.sending || step == SignInStep.verifying;
}

class SignInController extends Notifier<SignInState> {
  @override
  SignInState build() => const SignInState();

  Future<void> sendCode(String email) async {
    final repo = ref.read(authRepositoryProvider);
    if (repo == null) return;

    final trimmed = email.trim();
    state = state.copyWith(step: SignInStep.sending, email: trimmed);
    try {
      await repo.sendSignInCode(trimmed);
      state = state.copyWith(step: SignInStep.codeSent);
    } on AuthException catch (e) {
      state = state.copyWith(step: SignInStep.email, error: e.message);
    } catch (_) {
      state = state.copyWith(
        step: SignInStep.email,
        error: 'Could not send the code. Check the address and try again.',
      );
    }
  }

  Future<void> verifyCode(String code) async {
    final repo = ref.read(authRepositoryProvider);
    if (repo == null) return;

    state = state.copyWith(step: SignInStep.verifying);
    try {
      await repo.verifySignInCode(email: state.email, code: code);
      // Success: the auth stream fires and the router redirect takes over.
      ref.invalidate(myProfileProvider);
    } on AuthException catch (_) {
      // Supabase's raw message here is vague ("Token has expired or is
      // invalid"); say the two things the user can actually act on.
      state = state.copyWith(
        step: SignInStep.codeSent,
        error: 'That code is wrong or has expired. Check it, or resend.',
      );
    } catch (_) {
      state = state.copyWith(
        step: SignInStep.codeSent,
        error: 'Could not verify that code. Try again.',
      );
    }
  }

  /// Back to the email step, e.g. to correct a typo in the address.
  void changeEmail() => state = const SignInState();
}

final signInControllerProvider =
    NotifierProvider<SignInController, SignInState>(SignInController.new);
