import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/auth_provider.dart';
import '../../theme/palette.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = ref.watch(magicLinkControllerProvider);
    final sending = state.status == MagicLinkStatus.sending;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: state.status == MagicLinkStatus.sent
            ? _SentPanel(email: _controller.text.trim())
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Play anywhere',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to save your times, appear on leaderboards, and '
                      'challenge friends. Your solo games keep working either way.',
                      style: TextStyle(color: palette.noteText, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _controller,
                      autofillHints: const [AutofillHints.email],
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.go,
                      enabled: !sending,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return 'Enter your email address.';
                        // Deliberately permissive: the real check is whether
                        // the link arrives.
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(value)) {
                          return "That doesn't look like an email address.";
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (state.status == MagicLinkStatus.error) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.message ?? 'Something went wrong.',
                        style: TextStyle(color: palette.errorText),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: sending ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: sending
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Email me a sign-in link'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No password needed. The link signs you in and keeps you '
                      'signed in on this device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: palette.noteText),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    ref.read(magicLinkControllerProvider.notifier).send(_controller.text);
  }
}

class _SentPanel extends ConsumerWidget {
  final String email;

  const _SentPanel({required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.mark_email_read_outlined, size: 56, color: palette.primary),
        const SizedBox(height: 20),
        Text('Check your email',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        Text(
          'We sent a sign-in link to\n$email',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.noteText, height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          'Open it on this device to finish signing in. '
          'It can take a minute to arrive — check spam too.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: palette.noteText, height: 1.4),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () =>
              ref.read(magicLinkControllerProvider.notifier).reset(),
          child: const Text('Use a different address'),
        ),
      ],
    );
  }
}
