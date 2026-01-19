// lib/data/repositories/workout_history_repository.dart
import 'package:fitplan_creator/core/supabase/supabase_client.dart';
import 'package:fitplan_creator/core/supabase/supabase_config.dart';
import 'package:fitplan_creator/features/profile/models/user_profile.dart';

/// Репозиторий для работы с историей тренировок
class WorkoutHistoryRepository {
  final _client = AppSupabaseClient.instance;

  /// Добавить тренировку в историю
  /// 
  /// [userId] - ID пользователя (если null, используется текущий пользователь)
  /// [workout] - Объект WorkoutHistory
  /// 
  /// Возвращает созданную запись
  Future<WorkoutHistory> addWorkout(
    WorkoutHistory workout, [
    String? userId,
  ]) async {
    try {
      final targetUserId = userId ?? _client.currentUserId;
      if (targetUserId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final response = await _client.database
          .from(SupabaseConfig.workoutHistoryTable)
          .insert({
            'user_id': targetUserId,
            'plan_id': workout.id.contains('plan_') ? workout.id : null,
            'plan_name': workout.planName,
            'date': workout.date.toIso8601String(),
            'duration': workout.duration,
            'exercises_count': workout.exercisesCount,
            'completed': workout.completed,
          })
          .select()
          .single();

      return _mapResponseToWorkoutHistory(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Ошибка при добавлении тренировки: $e');
    }
  }

  /// Получить историю тренировок пользователя
  /// 
  /// [userId] - ID пользователя (если null, используется текущий пользователь)
  /// [limit] - Максимальное количество записей (по умолчанию 50)
  /// [offset] - Смещение для пагинации (по умолчанию 0)
  /// 
  /// Возвращает список тренировок
  Future<List<WorkoutHistory>> getWorkoutHistory([
    String? userId,
    int limit = 50,
    int offset = 0,
  ]) async {
    try {
      final targetUserId = userId ?? _client.currentUserId;
      if (targetUserId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final response = await _client.database
          .from(SupabaseConfig.workoutHistoryTable)
          .select()
          .eq('user_id', targetUserId)
          .order('date', ascending: false)
          .range(offset, offset + limit - 1);

      final data = response as List;
      return data
          .map((item) => _mapResponseToWorkoutHistory(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Ошибка при получении истории тренировок: $e');
    }
  }

  /// Получить тренировку по ID
  /// 
  /// [workoutId] - ID тренировки
  /// 
  /// Возвращает тренировку или null, если не найдена
  Future<WorkoutHistory?> getWorkout(String workoutId) async {
    try {
      final response = await _client.database
          .from(SupabaseConfig.workoutHistoryTable)
          .select()
          .eq('id', workoutId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return _mapResponseToWorkoutHistory(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Ошибка при получении тренировки: $e');
    }
  }

  /// Обновить тренировку в истории
  /// 
  /// [workoutId] - ID тренировки
  /// [workout] - Объект WorkoutHistory с обновленными данными
  /// 
  /// Возвращает обновленную тренировку
  Future<WorkoutHistory> updateWorkout(
    String workoutId,
    WorkoutHistory workout,
  ) async {
    try {
      final response = await _client.database
          .from(SupabaseConfig.workoutHistoryTable)
          .update({
            'plan_name': workout.planName,
            'date': workout.date.toIso8601String(),
            'duration': workout.duration,
            'exercises_count': workout.exercisesCount,
            'completed': workout.completed,
          })
          .eq('id', workoutId)
          .select()
          .single();

      return _mapResponseToWorkoutHistory(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Ошибка при обновлении тренировки: $e');
    }
  }

  /// Удалить тренировку из истории
  /// 
  /// [workoutId] - ID тренировки
  Future<void> deleteWorkout(String workoutId) async {
    try {
      await _client.database
          .from(SupabaseConfig.workoutHistoryTable)
          .delete()
          .eq('id', workoutId);
    } catch (e) {
      throw Exception('Ошибка при удалении тренировки: $e');
    }
  }

  /// Преобразовать ответ из БД в объект WorkoutHistory
  WorkoutHistory _mapResponseToWorkoutHistory(Map<String, dynamic> data) {
    return WorkoutHistory(
      id: data['id'] as String,
      planName: data['plan_name'] as String,
      date: DateTime.parse(data['date'] as String),
      duration: data['duration'] as int,
      exercisesCount: data['exercises_count'] as int,
      completed: data['completed'] as bool,
    );
  }
}
