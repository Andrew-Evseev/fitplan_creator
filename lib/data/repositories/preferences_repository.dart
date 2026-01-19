// lib/data/repositories/preferences_repository.dart
import 'package:fitplan_creator/core/supabase/supabase_client.dart';
import 'package:fitplan_creator/core/supabase/supabase_config.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';

/// Репозиторий для работы с предпочтениями пользователя
class PreferencesRepository {
  final _client = AppSupabaseClient.instance;

  /// Сохранить предпочтения пользователя
  /// 
  /// [userId] - ID пользователя (если null, используется текущий пользователь)
  /// [preferences] - Объект UserPreferences
  /// 
  /// Возвращает сохраненные предпочтения
  Future<UserPreferences> savePreferences(
    UserPreferences preferences, [
    String? userId,
  ]) async {
    try {
      final targetUserId = userId ?? _client.currentUserId;
      if (targetUserId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final preferencesData = preferences.toJson();
      preferencesData['createdAt'] = DateTime.now().toIso8601String();

      final response = await _client.database
          .from(SupabaseConfig.userPreferencesTable)
          .upsert({
            'user_id': targetUserId,
            'preferences_data': preferencesData,
          })
          .select()
          .single();

      final data = response as Map<String, dynamic>;
      final savedData = data['preferences_data'] as Map<String, dynamic>;
      return UserPreferences.fromJson(savedData);
    } catch (e) {
      throw Exception('Ошибка при сохранении предпочтений: $e');
    }
  }

  /// Получить предпочтения пользователя
  /// 
  /// [userId] - ID пользователя (если null, используется текущий пользователь)
  /// 
  /// Возвращает предпочтения или null, если не найдены
  Future<UserPreferences?> getPreferences([String? userId]) async {
    try {
      final targetUserId = userId ?? _client.currentUserId;
      if (targetUserId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final response = await _client.database
          .from(SupabaseConfig.userPreferencesTable)
          .select()
          .eq('user_id', targetUserId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final data = response as Map<String, dynamic>;
      final preferencesData = data['preferences_data'] as Map<String, dynamic>;
      return UserPreferences.fromJson(preferencesData);
    } catch (e) {
      throw Exception('Ошибка при получении предпочтений: $e');
    }
  }

  /// Обновить предпочтения пользователя
  /// 
  /// [userId] - ID пользователя (если null, используется текущий пользователь)
  /// [preferences] - Объект UserPreferences
  /// 
  /// Возвращает обновленные предпочтения
  Future<UserPreferences> updatePreferences(
    UserPreferences preferences, [
    String? userId,
  ]) async {
    return await savePreferences(preferences, userId);
  }
}
