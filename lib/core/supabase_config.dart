class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yldrboozmdwqpxrvfvxm.supabase.co',
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlsZHJib296bWR3cXB4cnZmdnhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzNDk5MTYsImV4cCI6MjA4ODkyNTkxNn0.h-Dxc05eQFJvJe3ezv-t1_jC1D9aVIq81R-505KzKJc',
  );
}
