import 'app_flavor.dart';

class SupabaseConfig {
  static const _prodUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yldrboozmdwqpxrvfvxm.supabase.co',
  );

  static const _demoUrl = String.fromEnvironment(
    'SUPABASE_URL_DEMO',
    defaultValue: _prodUrl,
  );

  static const _prodAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlsZHJib296bWR3cXB4cnZmdnhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzNDk5MTYsImV4cCI6MjA4ODkyNTkxNn0.h-Dxc05eQFJvJe3ezv-t1_jC1D9aVIq81R-505KzKJc',
  );

  static const _demoAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY_DEMO',
    defaultValue: _prodAnonKey,
  );

  static String get url => AppFlavorConfig.isDemo ? _demoUrl : _prodUrl;

  static String get anonKey =>
      AppFlavorConfig.isDemo ? _demoAnonKey : _prodAnonKey;
}
