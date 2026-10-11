/// Values come from Flutter `--dart-define` arguments.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  // Support both Supabase's current publishable-key name and the older
  // anon-key name used by existing env files.
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );
}
