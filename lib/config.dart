/// Identifiants Supabase.
///
/// OPTION A (recommandee) : passer au build via --dart-define
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// OPTION B (dev rapide) : remplacer les valeurs par defaut ci-dessous
///   puis ajouter lib/config.dart a .gitignore
class Config {
  Config._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dcrdokjjuucykrffgfdm.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjcmRva2pqdXVjeWtyZmZnZmRtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk1MzEzNTMsImV4cCI6MjA5NTEwNzM1M30.y99O3PxDGV8-bBgAjTbkPHQhGSuPxEdC3GpPGnA7irY',
  );

  /// true si les identifiants Supabase ont ete configures.
  /// false => l'app utilise les donnees mock locales (mode demo).
  static bool get isSupabaseConfigured =>
      !supabaseUrl.contains('YOUR_PROJECT_ID') &&
      !supabaseAnonKey.contains('YOUR_ANON_KEY');

  /// Cle API Anthropic pour la Recherche IA.
  /// flutter run --dart-define=CLAUDE_API_KEY=sk-ant-...
  /// Ou remplacer la valeur par defaut ci-dessous (ajouter a .gitignore).
  static const claudeApiKey = String.fromEnvironment(
    'CLAUDE_API_KEY',
    defaultValue: '',
  );

  static bool get isClaudeConfigured => claudeApiKey.isNotEmpty;
}
