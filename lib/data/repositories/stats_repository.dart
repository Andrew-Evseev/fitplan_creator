// lib/data/repositories/stats_repository.dart
import 'package:fitplan_creator/core/supabase/supabase_client.dart';
import 'package:fitplan_creator/core/supabase/supabase_config.dart';
import 'package:fitplan_creator/features/profile/models/user_profile.dart';

/// Репозиторий для работы со статистикой пользователя
class StatsRepository {
  final _client = AppSupabaseClient.instance;

  /// Получить статистику пользователя
  /// 
  /// [userId] - ID пользователя (если null, используется текущий пользователь)
  /// 
  /// Возвращает статистику или null, если не найдена
  Future<UserStats?> getStats([String? userId]) async {
    try {
      final targetUserId = userId ?? _client.currentUserId;
      if (targetUserId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final response = await _client.database
          .from(SupabaseConfig.userStatsTable)
          .select()
          .eq('user_id', targetUserId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return _mapResponseToStats(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Ошибка при получении статистики: $e');
    }
  }

  /// Обновить статистику на основе данных тренировки
  /// 
  /// [userId] - ID пользователя (если null, используется текущий пользователь)
  /// [workoutData] - Данные тренировки для обновления статистики
  /// 
  /// Обычно вызывается автоматически через триггер БД,
  /// но может быть вызван вручную для дополнительной обработки
  Future<UserStats> updateStats(
    Map<String, dynamic> workoutData, [
    String? userId,
  ]) async {
    try {
      final targetUserId = userId ?? _client.currentUserId;
      if (targetUserId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Получаем текущую статистику
      final currentStats = await getStats(targetUserId);
      if (currentStats == null) {
        throw Exception('Статистика не найдена');
      }

      // Триггер в БД уже обновил статистику,
      // но мы можем получить обновленную версию
      return (await getStats(targetUserId))!;
    } catch (e) {
      throw Exception('Ошибка при обновлении статистики: $e');
    }
  }

  /// Сбросить streak (серию дней подряд)
  /// 
  /// [userId] - ID пользователя (если null, используется текущий пользователь)
  /// 
  /// Используется, когда пользователь пропустил тренировку
  Future<UserStats> resetStreak([String? userId]) async {
    try {
      final targetUserId = userId ?? _client.currentUserId;
      if (targetUserId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final response = await _client.database
          .from(SupabaseConfig.userStatsTable)
          .update({
            'current_streak': 0,
          })
          .eq('user_id', targetUserId)
          .select()
          .single();

      return _mapResponseToStats(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Ошибка при сбросе streak: $e');
    }
  }

  /// Преобразовать ответ из БД в объект UserStats
  UserStats _mapResponseToStats(Map<String, dynamic> data) {
    return UserStats(
      totalWorkouts: data['total_workouts'] as int,
      totalExercises: data['total_exercises'] as int,
      totalMinutes: data['total_minutes'] as int,
      currentStreak: data['current_streak'] as int,
      maxStreak: data['max_streak'] as int,
      muscleGroupDistribution: Map<String, int>.from(
        data['muscle_group_distribution'] as Map? ?? {},
      ),
      averageWorkoutTime: (data['average_workout_time'] as num).toDouble(),
    );
  }
}
