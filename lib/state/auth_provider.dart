import 'dart:async';

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

  /// Seconds left on the per-address send cooldown, 0 when clear.
  final int cooldownSeconds;

  const SignInState({
    this.step = SignInStep.email,
    this.email = '',
    this.error,
    this.cooldownSeconds = 0,
  });

  SignInState copyWith({
    SignInStep? step,
    String? email,
    String? error,
    int? cooldownSeconds,
  }) {
    return SignInState(
      step: step ?? this.step,
      email: email ?? this.email,
      // Explicitly clearable: each transition should drop the previous error.
      error: error,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
    );
  }

  bool get busy =>
      step == SignInStep.sending || step == SignInStep.verifying;

  bool get canSend => !busy && cooldownSeconds == 0;
}

class SignInController extends Notifier<SignInState> {
  Timer? _cooldownTimer;

  @override
  SignInState build() {
    ref.onDispose(() => _cooldownTimer?.cancel());
    return const SignInState();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    state = state.copyWith(cooldownSeconds: seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = state.cooldownSeconds - 1;
      if (left <= 0) {
        t.cancel();
        state = state.copyWith(cooldownSeconds: 0);
      } else {
        state = state.copyWith(cooldownSeconds: left);
      }
    });
  }

  Future<void> sendCode(String email) async {
    final repo = ref.read(authRepositoryProvider);
    if (repo == null) return;

    final trimmed = email.trim();
    state = state.copyWith(step: SignInStep.sending, email: trimmed);
    try {
      await repo.sendSignInCode(trimmed);
      state = state.copyWith(step: SignInStep.codeSent);
      // Supabase applies the cooldown to every request, including the one
      // that just succeeded -- start it now so "Resend" is correctly
      // disabled rather than failing when tapped.
      _startCooldown(60);
    } on AuthRateLimited catch (e) {
      // Not an error the user caused. If a code was already sent, move them
      // forward to enter it rather than stranding them on the email step.
      state = state.copyWith(
        step: state.email.isNotEmpty && state.step == SignInStep.sending
            ? SignInStep.codeSent
            : SignInStep.email,
      );
      _startCooldown(e.retryAfterSeconds);
    } on AuthException catch (e) {
      state = state.copyWith(step: SignInStep.email, error: e.message);
    } catch (_) {
      state = state.copyWith(
        step: SignInStep.email,
        error: 'Could not reach the server. Check your connection.',
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
  /// Keeps any active cooldown -- it's enforced server-side per address, so
  /// pretending it's gone would just produce another failure.
  void changeEmail() =>
      state = SignInState(cooldownSeconds: state.cooldownSeconds);
}

final signInControllerProvider =
    NotifierProvider<SignInController, SignInState>(SignInController.new);
