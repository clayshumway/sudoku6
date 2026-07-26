/// Supabase connection details.
///
/// The anon key is **public by design** -- it ships inside every Supabase web
/// bundle and identifies the project, not the user. Row Level Security (see
/// `supabase/migrations/`) is the actual security boundary. The `service_role`
/// key is a different thing entirely and must never appear in this app.
///
/// Values can be overridden at build time without editing source:
///   flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  SupabaseConfig._();

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gwbckrvodutnwiltnqzc.supabase.co',
  );

  /// Supabase's modern "publishable" key, which replaced the legacy `anon`
  /// JWT. The SDK forwards it verbatim as the `apikey` header and never
  /// inspects it, so the newer opaque format works unchanged.
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_MEHM5CLv-lVoZvBTER_VxQ_5O4zZKeZ',
  );

  /// Where the magic link sends the user back to.
  ///
  /// Must also be listed in the Supabase dashboard under
  /// Authentication -> URL Configuration -> Redirect URLs, or the link will
  /// bounce to the site root without a session.
  static const webRedirect = 'https://s6.clayshumway.com/';

  /// Deep link for the Android build. Registered as an intent filter in
  /// AndroidManifest.xml.
  static const mobileRedirect = 'com.clayshumway.sudoku6://login-callback/';

  /// When false the app runs fully offline and every social feature is hidden,
  /// which keeps solo play working if the backend is unreachable or
  /// unconfigured.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
