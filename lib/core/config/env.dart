/// Runtime configuration supplied with `--dart-define-from-file=env.json`.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing Supabase configuration. Copy env.example.json to env.json '
        'and run with --dart-define-from-file=env.json.',
      );
    }
  }
}
