import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'data/hive_boxes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();

  // Optional on purpose: with no credentials the app still runs, just without
  // account features. A backend outage or a misconfigured build should never
  // take solo play down with it.
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
        authOptions: const FlutterAuthClientOptions(
          // Persists the session and refreshes tokens in the background, so
          // signing in once keeps you signed in on that device.
          authFlowType: AuthFlowType.pkce,
        ),
      );
    } catch (e) {
      debugPrint('Supabase init failed, continuing offline: $e');
    }
  }

  runApp(const ProviderScope(child: SudokuApp()));
}
