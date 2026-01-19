// lib/data/repositories/profile_repository.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:fitplan_creator/core/supabase/supabase_client.dart';
import 'package:fitplan_creator/core/supabase/supabase_config.dart';

/// Репозиторий для работы с профилями пользователей
class ProfileRepository {
  final _client = AppSupabaseClient.instance;
  
  /// Получить профиль пользователя
  /// 
  /// [userId] - ID пользователя (если null, используется текущий пользователь)
  /// 
  /// Возвращает профиль или null, если не найден
  Future<Map<String, dynamic>?> getProfile([String? userId]) async {
    try {
      final targetUserId = userId ?? _client.currentUserId;
      if (targetUserId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final response = await _client.database
          .from(SupabaseConfig.profilesTable)
          .select()
          .eq('id', targetUserId)
          .single();

      return response as Map<String, dynamic>?;
    } on supabase.PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // Запись не найдена
        return null;
      }
      rethrow;
    } catch (e) {
      throw Exception('Ошибка при получении профиля: $e');
    }
  }

  /// Обновить профиль пользователя
  /// 
  /// [userId] - ID пользователя (если null, используется текущий пользователь)
  /// [data] - Данные для обновления (name, avatar_url и т.д.)
  /// 
  /// Возвращает обновленный профиль
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data, [
    String? userId,
  ]) async {
    try {
      final targetUserId = userId ?? _client.currentUserId;
      if (targetUserId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final response = await _client.database
          .from(SupabaseConfig.profilesTable)
          .update(data)
          .eq('id', targetUserId)
          .select()
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Ошибка при обновлении профиля: $e');
    }
  }

  /// Загрузить аватар пользователя
  /// 
  /// [userId] - ID пользователя (если null, используется текущий пользователь)
  /// [file] - Файл изображения
  /// 
  /// Возвращает URL загруженного аватара
  Future<String> uploadAvatar(File file, [String? userId]) async {
    try {
      final targetUserId = userId ?? _client.currentUserId;
      if (targetUserId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final fileName = '$targetUserId-${DateTime.now().millisecondsSinceEpoch}';
      final fileExt = file.path.split('.').last;
      final filePath = 'avatars/$fileName.$fileExt';

      // Загрузить файл в Storage
      await _client.client.storage
          .from('avatars')
          .upload(filePath, file, fileOptions: supabase.FileOptions(
            upsert: true,
            contentType: 'image/$fileExt',
          ));

      // Получить публичный URL
      final url = _client.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // Обновить профиль с новым URL аватара
      await updateProfile({'avatar_url': url});

      return url;
    } catch (e) {
      throw Exception('Ошибка при загрузке аватара: $e');
    }
  }
}
