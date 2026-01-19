// lib/core/supabase/supabase_config.dart
class SupabaseConfig {
  // Supabase сервер на Timeweb Cloud
  static const String url = 'http://176.124.208.227:8000';
  
  // Anon key для клиентских запросов
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzY4NTkwMDAwLCJleHAiOjE5MjYzNTY0MDB9.pzgs57AYaSmYEIRMiJT70OET4Pp8nNCLEEXXLhiscrI';
  
  // Service role key (только для серверных операций, НЕ использовать в клиенте!)
  // static const String serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaXNzIjoic3VwYWJhc2UiLCJpYXQiOjE3Njg1OTAwMDAsImV4cCI6MTkyNjM1NjQwMH0.bBjvbouIR1J31JZ_K0nYNiPjUuPcLGw6tjTYKz5M2UE';
  
  // Имя схемы БД
  static const String schema = 'public';
  
  // Имена таблиц
  static const String profilesTable = 'profiles';
  static const String userPreferencesTable = 'user_preferences';
  static const String workoutPlansTable = 'workout_plans';
  static const String workoutHistoryTable = 'workout_history';
  static const String userStatsTable = 'user_stats';
  static const String userSettingsTable = 'user_settings';
}
