// lib/core/supabase/supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import 'supabase_config.dart';

/// Инициализация и получение экземпляра Supabase клиента
class AppSupabaseClient {
  static AppSupabaseClient? _instance;
  static AppSupabaseClient get instance {
    _instance ??= AppSupabaseClient._();
    return _instance!;
  }

  AppSupabaseClient._();

  /// Инициализировать Supabase
  /// Вызывать один раз при запуске приложения (в main.dart)
  static Future<void> initialize() async {
    await supabase_flutter.Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  /// Получить клиент Supabase
  supabase_flutter.SupabaseClient get client => supabase_flutter.Supabase.instance.client;

  /// Получить клиент аутентификации
  supabase_flutter.GoTrueClient get auth => client.auth;

  /// Получить клиент базы данных
  supabase_flutter.PostgrestClient get database => client.rest;

  /// Проверить, авторизован ли пользователь
  bool get isAuthenticated => client.auth.currentUser != null;

  /// Получить текущего пользователя
  supabase_flutter.User? get currentUser => client.auth.currentUser;

  /// Получить ID текущего пользователя
  String? get currentUserId => client.auth.currentUser?.id;

  /// Подписаться на изменения состояния аутентификации
  Stream<supabase_flutter.AuthState> get authStateChanges => client.auth.onAuthStateChange;
}

/// Глобальная переменная для удобного доступа к клиенту
final supabase = AppSupabaseClient.instance.client;
