import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/auth_provider.dart';
import '../../theme/palette.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signInControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: state.step == SignInStep.email ||
                state.step == SignInStep.sending
            ? const _EmailStep()
            : const _CodeStep(),
      ),
    );
  }
}

class _EmailStep extends ConsumerStatefulWidget {
  const _EmailStep();

  @override
  ConsumerState<_EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends ConsumerState<_EmailStep> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Preserve the address when returning from the code step.
    _controller.text = ref.read(signInControllerProvider).email;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    ref.read(signInControllerProvider.notifier).sendCode(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = ref.watch(signInControllerProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Play anywhere',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Sign in to save your times, appear on leaderboards, and challenge '
            'friends. Your solo games keep working either way.',
            style: TextStyle(color: palette.noteText, height: 1.4),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _controller,
            autofillHints: const [AutofillHints.email],
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.go,
            enabled: !state.busy,
            decoration: const InputDecoration(
              labelText: 'Email address',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Enter your email address.';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                return "That doesn't look like an email address.";
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(state.error!, style: TextStyle(color: palette.errorText)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: state.canSend ? _submit : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: state.busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(state.cooldownSeconds > 0
                      ? 'Wait ${state.cooldownSeconds}s'
                      : 'Email me a sign-in code'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            state.cooldownSeconds > 0
                ? 'A code was requested recently. You can ask for another in '
                    '${state.cooldownSeconds}s.'
                : 'No password needed. We email you a 6-digit code.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: palette.noteText),
          ),
        ],
      ),
    );
  }
}

class _CodeStep extends ConsumerStatefulWidget {
  const _CodeStep();

  @override
  ConsumerState<_CodeStep> createState() => _CodeStepState();
}

class _CodeStepState extends ConsumerState<_CodeStep> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.length < 6) return;
    ref.read(signInControllerProvider.notifier).verifyCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = ref.watch(signInControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.mark_email_read_outlined, size: 48, color: palette.primary),
        const SizedBox(height: 16),
        Text('Check your email',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to\n${state.email}',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.noteText, height: 1.4),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _controller,
          autofocus: true,
          enabled: !state.busy,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.go,
          textAlign: TextAlign.center,
          maxLength: 6,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
              fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: 10),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '000000',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            setState(() {});
            // Six digits is unambiguous -- submit without making them
            // reach for a button.
            if (v.trim().length == 6) _submit();
          },
          onSubmitted: (_) => _submit(),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 8),
          Text(state.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.errorText)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed:
              state.busy || _controller.text.trim().length < 6 ? null : _submit,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: state.busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Sign in'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: state.canSend
                  ? () => ref
                      .read(signInControllerProvider.notifier)
                      .sendCode(state.email)
                  : null,
              child: Text(state.cooldownSeconds > 0
                  ? 'Resend in ${state.cooldownSeconds}s'
                  : 'Resend code'),
            ),
            TextButton(
              onPressed: state.busy
                  ? null
                  : () => ref
                      .read(signInControllerProvider.notifier)
                      .changeEmail(),
              child: const Text('Change email'),
            ),
          ],
        ),
        Text(
          'Codes can take a minute to arrive — check spam too.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: palette.noteText),
        ),
      ],
    );
  }
}
