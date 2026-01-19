// lib/core/supabase/supabase_config.dart
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class SupabaseConfig {
  // Supabase URL - загружается из переменных окружения
  // Для Flutter web используем compile-time переменные
  // Для других платформ можно использовать flutter_dotenv
  static String get url {
    // Попытка получить из compile-time переменной
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Fallback: попытка получить из переменной окружения процесса (для debug)
    final runtimeUrl = Platform.environment['SUPABASE_URL'];
    if (runtimeUrl != null && runtimeUrl.isNotEmpty) {
      return runtimeUrl;
    }
    
    // В продакшене это должно быть установлено!
    if (kDebugMode) {
      // Только для локальной разработки - замените на свои значения
      throw Exception(
        'SUPABASE_URL не установлен!\n'
        'Установите переменную окружения SUPABASE_URL или используйте:\n'
        'flutter run --dart-define=SUPABASE_URL=your_url'
      );
    }
    
    throw Exception('SUPABASE_URL не установлен!');
  }
  
  // Anon key для клиентских запросов
  static String get anonKey {
    // Попытка получить из compile-time переменной
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }
    
    // Fallback: попытка получить из переменной окружения процесса
    final runtimeKey = Platform.environment['SUPABASE_ANON_KEY'];
    if (runtimeKey != null && runtimeKey.isNotEmpty) {
      return runtimeKey;
    }
    
    // В продакшене это должно быть установлено!
    if (kDebugMode) {
      throw Exception(
        'SUPABASE_ANON_KEY не установлен!\n'
        'Установите переменную окружения SUPABASE_ANON_KEY или используйте:\n'
        'flutter run --dart-define=SUPABASE_ANON_KEY=your_key'
      );
    }
    
    throw Exception('SUPABASE_ANON_KEY не установлен!');
  }
  
  // Service role key НЕ должен быть в клиентском коде!
  // Используется только на сервере через переменные окружения
  
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
