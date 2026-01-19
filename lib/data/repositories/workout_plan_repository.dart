// lib/data/repositories/workout_plan_repository.dart
import 'package:fitplan_creator/core/supabase/supabase_client.dart';
import 'package:fitplan_creator/core/supabase/supabase_config.dart';
import 'package:fitplan_creator/data/models/workout_plan.dart';

/// Репозиторий для работы с планами тренировок
class WorkoutPlanRepository {
  final _client = AppSupabaseClient.instance;

  /// Создать новый план тренировок
  /// 
  /// [userId] - ID пользователя (если null, используется текущий пользователь)
  /// [plan] - Объект WorkoutPlan
  /// 
  /// Возвращает созданный план с ID
  Future<WorkoutPlan> createPlan(WorkoutPlan plan, [String? userId]) async {
    try {
      final targetUserId = userId ?? _client.currentUserId;
      if (targetUserId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final planData = plan.toJson();
      final response = await _client.database
          .from(SupabaseConfig.workoutPlansTable)
          .insert({
            'user_id': targetUserId,
            'name': plan.name,
            'description': plan.description,
            'training_system': plan.trainingSystem?.displayName,
            'plan_data': planData,
          })
          .select()
          .single();

      return _mapResponseToPlan(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Ошибка при создании плана: $e');
    }
  }

  /// Получить все планы пользователя
  /// 
  /// [userId] - ID пользователя (если null, используется текущий пользователь)
  /// 
  /// Возвращает список планов
  Future<List<WorkoutPlan>> getPlans([String? userId]) async {
    try {
      final targetUserId = userId ?? _client.currentUserId;
      if (targetUserId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final response = await _client.database
          .from(SupabaseConfig.workoutPlansTable)
          .select()
          .eq('user_id', targetUserId)
          .order('created_at', ascending: false);

      final data = response as List;
      return data.map((item) => _mapResponseToPlan(item as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Ошибка при получении планов: $e');
    }
  }

  /// Получить план по ID
  /// 
  /// [planId] - ID плана
  /// 
  /// Возвращает план или null, если не найден
  Future<WorkoutPlan?> getPlan(String planId) async {
    try {
      final response = await _client.database
          .from(SupabaseConfig.workoutPlansTable)
          .select()
          .eq('id', planId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return _mapResponseToPlan(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Ошибка при получении плана: $e');
    }
  }

  /// Обновить план тренировок
  /// 
  /// [planId] - ID плана
  /// [plan] - Объект WorkoutPlan с обновленными данными
  /// 
  /// Возвращает обновленный план
  Future<WorkoutPlan> updatePlan(String planId, WorkoutPlan plan) async {
    try {
      final planData = plan.toJson();
      final response = await _client.database
          .from(SupabaseConfig.workoutPlansTable)
          .update({
            'name': plan.name,
            'description': plan.description,
            'training_system': plan.trainingSystem?.displayName,
            'plan_data': planData,
          })
          .eq('id', planId)
          .select()
          .single();

      return _mapResponseToPlan(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Ошибка при обновлении плана: $e');
    }
  }

  /// Удалить план тренировок
  /// 
  /// [planId] - ID плана
  Future<void> deletePlan(String planId) async {
    try {
      await _client.database
          .from(SupabaseConfig.workoutPlansTable)
          .delete()
          .eq('id', planId);
    } catch (e) {
      throw Exception('Ошибка при удалении плана: $e');
    }
  }

  /// Сохранить план (alias для createPlan или updatePlan)
  /// 
  /// [userId] - ID пользователя (если null, используется текущий пользователь)
  /// [plan] - Объект WorkoutPlan
  /// 
  /// Если у плана есть ID и он существует в БД, обновит его, иначе создаст новый
  Future<WorkoutPlan> savePlan(WorkoutPlan plan, [String? userId]) async {
    // Если план уже имеет ID, попытаемся обновить его
    if (plan.id.isNotEmpty) {
      try {
        final existingPlan = await getPlan(plan.id);
        if (existingPlan != null) {
          return await updatePlan(plan.id, plan);
        }
      } catch (e) {
        // Если план не найден, создадим новый
      }
    }

    // Создаем новый план
    return await createPlan(plan, userId);
  }

  /// Преобразовать ответ из БД в объект WorkoutPlan
  WorkoutPlan _mapResponseToPlan(Map<String, dynamic> data) {
    final planData = data['plan_data'] as Map<String, dynamic>;
    // Обновляем ID из БД
    planData['id'] = data['id'] as String;
    planData['userId'] = data['user_id'] as String;
    planData['createdAt'] = data['created_at'] as String;
    if (data['updated_at'] != null) {
      planData['updatedAt'] = data['updated_at'] as String;
    }
    // Если training_system есть в БД, используем его
    if (data['training_system'] != null) {
      planData['trainingSystem'] = data['training_system'] as String;
    }
    return WorkoutPlan.fromJson(planData);
  }
}
