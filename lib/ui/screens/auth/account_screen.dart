import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/auth_provider.dart';
import '../../theme/palette.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final user = ref.watch(authUserProvider).value;
    final profile = ref.watch(myProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Username'),
                  subtitle: Text(profile?.username ?? 'Not set'),
                ),
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('Email'),
                  subtitle: Text(user.email),
                ),
                const Divider(height: 32),
                ListTile(
                  leading: Icon(Icons.logout, color: palette.errorText),
                  title: Text('Sign out',
                      style: TextStyle(color: palette.errorText)),
                  onTap: () => _confirmSignOut(context, ref),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    'Signing out only affects this device. Your times and '
                    'username stay on your account.',
                    style: TextStyle(fontSize: 12, color: palette.noteText),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            "You'll need another email link to sign back in on this device."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out')),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(authRepositoryProvider)?.signOut();
    ref.invalidate(myProfileProvider);
  }
}
