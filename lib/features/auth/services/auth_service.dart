// lib/features/auth/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:fitplan_creator/core/supabase/supabase_client.dart';

/// Сервис для работы с аутентификацией
class AuthService {
  final _client = AppSupabaseClient.instance;
  
  /// Получить текущего пользователя
  supabase.User? get currentUser => _client.currentUser;
  
  /// Проверить, авторизован ли пользователь
  bool get isAuthenticated => _client.isAuthenticated;
  
  /// Получить ID текущего пользователя
  String? get currentUserId => _client.currentUserId;
  
  /// Подписаться на изменения состояния аутентификации
  Stream<supabase.AuthState> get authStateChanges => _client.authStateChanges;

  /// Регистрация нового пользователя
  /// 
  /// [email] - Email пользователя
  /// [password] - Пароль пользователя
  /// [name] - Имя пользователя
  /// 
  /// Возвращает созданного пользователя
  /// Выбрасывает [AuthException] в случае ошибки
  Future<supabase.User> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('🔐 AuthService.signUp: email=$email, name=$name');
      
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
        },
      );

      print('📦 Ответ от Supabase: user=${response.user?.id}, session=${response.session?.accessToken != null}');

      if (response.user == null) {
        print('❌ Пользователь не создан');
        throw supabase.AuthException('Не удалось создать пользователя');
      }

      print('✅ Пользователь создан: ${response.user!.id}');
      print('📧 Email: ${response.user!.email}');
      print('📧 Email подтвержден: ${response.user!.emailConfirmedAt != null}');
      
      // Проверяем, нужно ли подтверждение email
      if (response.session == null) {
        print('⚠️ Сессия не создана - требуется подтверждение email');
        // Пользователь создан, но нужно подтвердить email
        // В этом случае пользователь все равно должен быть создан в auth.users
        // и триггер должен сработать
      } else {
        print('✅ Сессия создана, пользователь авторизован');
      }

      return response.user!;
    } on supabase.AuthException catch (e) {
      print('❌ AuthException: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('❌ Ошибка при регистрации: $e');
      print('Stack trace: $stackTrace');
      throw supabase.AuthException('Ошибка при регистрации: $e');
    }
  }

  /// Вход существующего пользователя
  /// 
  /// [email] - Email пользователя
  /// [password] - Пароль пользователя
  /// 
  /// Возвращает пользователя после успешного входа
  /// Выбрасывает [AuthException] в случае ошибки
  Future<supabase.User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw supabase.AuthException('Не удалось войти');
      }

      return response.user!;
    } on supabase.AuthException catch (e) {
      rethrow;
    } catch (e) {
      throw supabase.AuthException('Ошибка при входе: $e');
    }
  }

  /// Выход текущего пользователя
  /// 
  /// Выбрасывает [AuthException] в случае ошибки
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on supabase.AuthException catch (e) {
      rethrow;
    } catch (e) {
      throw supabase.AuthException('Ошибка при выходе: $e');
    }
  }

  /// Сброс пароля
  /// 
  /// [email] - Email пользователя
  /// 
  /// Выбрасывает [AuthException] в случае ошибки
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on supabase.AuthException catch (e) {
      rethrow;
    } catch (e) {
      throw supabase.AuthException('Ошибка при сбросе пароля: $e');
    }
  }

  /// Обновить данные пользователя
  /// 
  /// [data] - Данные для обновления (например, {'name': 'Новое имя'})
  /// 
  /// Выбрасывает [AuthException] в случае ошибки
  Future<supabase.User> updateUser(Map<String, dynamic> data) async {
    try {
      final response = await _client.auth.updateUser(
        supabase.UserAttributes(data: data),
      );

      if (response.user == null) {
        throw supabase.AuthException('Не удалось обновить пользователя');
      }

      return response.user!;
    } on supabase.AuthException catch (e) {
      rethrow;
    } catch (e) {
      throw supabase.AuthException('Ошибка при обновлении пользователя: $e');
    }
  }

  /// Получить текущую сессию
  supabase.Session? get currentSession => _client.auth.currentSession;
}
