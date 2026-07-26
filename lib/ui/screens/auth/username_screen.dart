import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/profile_repository.dart';
import '../../../state/auth_provider.dart';
import '../../routing/app_router.dart';
import '../../theme/palette.dart';

/// Shown once, after a user signs in without having claimed a username.
class UsernameScreen extends ConsumerStatefulWidget {
  const UsernameScreen({super.key});

  @override
  ConsumerState<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends ConsumerState<UsernameScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  String? _validationError;
  bool _checking = false;
  bool? _available;
  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _available = null;
      _submitError = null;
      _validationError = validateUsername(value);
    });
    if (_validationError != null) return;

    // Debounced so typing doesn't fire a request per keystroke.
    _debounce = Timer(const Duration(milliseconds: 400), () => _check(value));
  }

  Future<void> _check(String value) async {
    final repo = ref.read(profileRepositoryProvider);
    if (repo == null) return;
    setState(() => _checking = true);
    try {
      final free = await repo.isUsernameAvailable(value);
      if (!mounted || _controller.text.trim() != value.trim()) return;
      setState(() {
        _available = free;
        _checking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _checking = false);
    }
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    final error = validateUsername(value);
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }

    final repo = ref.read(profileRepositoryProvider);
    if (repo == null) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      await repo.claimUsername(value);

      // Wait for the profile to actually reflect the new username before
      // moving on -- the router redirect holds while it's loading, so handing
      // off mid-flight leaves the button spinning on a claim that succeeded.
      ref.invalidate(myProfileProvider);
      try {
        await ref.read(myProfileProvider.future);
      } catch (_) {
        // The username is claimed either way; don't block on a read-back.
      }

      if (!mounted) return;
      // Navigate explicitly rather than waiting for the redirect to fire.
      // The redirect still runs on this navigation and will keep us here,
      // so this is a hand-off, not a bypass.
      //
      // Pop when this screen was pushed from somewhere specific (an invite
      // link needs a username before it can join, and should resume where it
      // left off). Only fall back to the account screen when it's the end of
      // the first-run sign-in flow with nothing to return to.
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.account);
      }
    } on UsernameTakenException {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _available = false;
        _submitError = 'That username was just taken. Try another.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = 'Could not save that username. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final value = _controller.text.trim();
    final canSubmit = !_submitting &&
        _validationError == null &&
        value.isNotEmpty &&
        _available != false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick a username'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'This is how you appear on leaderboards and in challenges.',
              style: TextStyle(color: palette.noteText, height: 1.4),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_submitting,
              textInputAction: TextInputAction.go,
              onChanged: _onChanged,
              onSubmitted: (_) => canSubmit ? _submit() : null,
              decoration: InputDecoration(
                labelText: 'Username',
                border: const OutlineInputBorder(),
                errorText: _validationError ?? _submitError,
                suffixIcon: _buildStatusIcon(palette),
                helperText: '3–20 characters. Letters, numbers, underscores.',
              ),
            ),
            if (_available == false && _submitError == null) ...[
              const SizedBox(height: 8),
              Text('That username is taken.',
                  style: TextStyle(color: palette.errorText)),
            ],
            if (_available == true) ...[
              const SizedBox(height: 8),
              Text('$value is available.',
                  style: TextStyle(color: palette.primary)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: canSubmit ? _submit : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildStatusIcon(Palette palette) {
    if (_checking) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_available == true) {
      return Icon(Icons.check_circle, color: palette.primary);
    }
    if (_available == false) {
      return Icon(Icons.cancel, color: palette.errorText);
    }
    return null;
  }
}
