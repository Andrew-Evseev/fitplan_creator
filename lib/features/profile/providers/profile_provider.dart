// lib/features/profile/providers/profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import 'package:fitplan_creator/data/models/workout_plan.dart';
import 'package:fitplan_creator/data/repositories/profile_repository.dart';
import 'package:fitplan_creator/data/repositories/stats_repository.dart';
import 'package:fitplan_creator/data/repositories/workout_history_repository.dart';
import 'package:fitplan_creator/core/supabase/supabase_client.dart' as supabase;

class ProfileNotifier extends StateNotifier<UserProfile> {
  final _profileRepo = ProfileRepository();
  final _statsRepo = StatsRepository();
  final _historyRepo = WorkoutHistoryRepository();
  
  ProfileNotifier() : super(_initialProfile()) {
    _loadProfile();
  }

  static UserProfile _initialProfile() {
    final userId = supabase.AppSupabaseClient.instance.currentUserId;
    return UserProfile.initial(userId ?? 'guest', userId != null ? 'Пользователь' : 'Гость');
  }

  /// Загрузить профиль из Supabase
  Future<void> _loadProfile() async {
    try {
      final userId = supabase.AppSupabaseClient.instance.currentUserId;
      if (userId == null) {
        // Пользователь не авторизован, используем начальный профиль
        return;
      }

      // Загружаем данные параллельно
      final profileData = await _profileRepo.getProfile(userId);
      final stats = await _statsRepo.getStats(userId);
      final history = await _historyRepo.getWorkoutHistory(userId);

      if (profileData == null) {
        // Профиль не найден, создаем начальный
        state = UserProfile.initial(userId, 'Пользователь');
        return;
      }

      // Преобразуем данные из БД в UserProfile
      final userProfile = UserProfile(
        id: profileData['id'] as String,
        name: profileData['name'] as String,
        email: profileData['email'] as String?,
        avatarUrl: profileData['avatar_url'] as String?,
        joinDate: DateTime.parse(profileData['created_at'] as String),
        stats: stats ?? UserStats.initial(),
        settings: UserSettings.defaultSettings(), // TODO: загрузить из БД
        workoutHistory: history,
        savedPlans: [], // TODO: загрузить из workout_plans
      );

      state = userProfile;
    } catch (e) {
      // В случае ошибки оставляем начальное состояние
      print('Ошибка при загрузке профиля: $e');
    }
  }

  /// Обновление статистики при завершении тренировки
  Future<void> updateStatsAfterWorkout({
    required int duration,
    required int exercisesCount,
    required Map<String, int> muscleGroups,
    String? planId,
    String? planName,
  }) async {
    try {
      final userId = supabase.AppSupabaseClient.instance.currentUserId;
      if (userId == null) return;

      // Добавляем тренировку в историю (триггер автоматически обновит статистику)
      final workout = WorkoutHistory(
        id: 'workout_${DateTime.now().millisecondsSinceEpoch}',
        planName: planName ?? 'Тренировка',
        date: DateTime.now(),
        duration: duration,
        exercisesCount: exercisesCount,
        completed: true,
      );

      await _historyRepo.addWorkout(workout, userId);

      // Перезагружаем профиль, чтобы получить обновленную статистику
      await _loadProfile();
    } catch (e) {
      // В случае ошибки обновляем локальное состояние
      _updateStatsLocally(duration, exercisesCount, muscleGroups, planName);
    }
  }

  /// Локальное обновление статистики (fallback)
  void _updateStatsLocally(
    int duration,
    int exercisesCount,
    Map<String, int> muscleGroups,
    String? planName,
  ) {
    final currentState = state;

    final now = DateTime.now();
    final lastWorkoutDate = currentState.workoutHistory.isNotEmpty
        ? currentState.workoutHistory.last.date
        : DateTime(0);
    
    final daysSinceLastWorkout = now.difference(lastWorkoutDate).inDays;
    int newStreak = currentState.stats.currentStreak;
    
    if (daysSinceLastWorkout <= 1) {
      newStreak++;
    } else {
      newStreak = 1;
    }

    final newMaxStreak = newStreak > currentState.stats.maxStreak
        ? newStreak
        : currentState.stats.maxStreak;

    final updatedDistribution = Map<String, int>.from(currentState.stats.muscleGroupDistribution);
    muscleGroups.forEach((muscle, count) {
      updatedDistribution[muscle] = (updatedDistribution[muscle] ?? 0) + count;
    });

    final newTotalWorkouts = currentState.stats.totalWorkouts + 1;
    final newAverageTime = (currentState.stats.totalMinutes + duration) / newTotalWorkouts;

    state = currentState.copyWith(
      stats: currentState.stats.copyWith(
        totalWorkouts: newTotalWorkouts,
        totalExercises: currentState.stats.totalExercises + exercisesCount,
        totalMinutes: currentState.stats.totalMinutes + duration,
        currentStreak: newStreak,
        maxStreak: newMaxStreak,
        muscleGroupDistribution: updatedDistribution,
        averageWorkoutTime: newAverageTime,
      ),
      workoutHistory: [
        ...currentState.workoutHistory,
        WorkoutHistory(
          id: 'workout_${DateTime.now().millisecondsSinceEpoch}',
          planName: planName ?? 'Тренировка ${currentState.stats.totalWorkouts + 1}',
          date: now,
          duration: duration,
          exercisesCount: exercisesCount,
          completed: true,
        ),
      ],
    );
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    final currentState = state;

    try {
      // TODO: Сохранить настройки в БД через user_settings таблицу
      state = currentState.copyWith(settings: newSettings);
    } catch (e) {
      // В случае ошибки обновляем локально
      state = currentState.copyWith(settings: newSettings);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    final currentState = state;

    try {
      final userId = supabase.AppSupabaseClient.instance.currentUserId;
      if (userId != null) {
        final updateData = <String, dynamic>{};
        if (name != null) updateData['name'] = name;
        if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

        if (updateData.isNotEmpty) {
          await _profileRepo.updateProfile(updateData, userId);
        }
      }

      state = currentState.copyWith(
        name: name ?? currentState.name,
        email: email ?? currentState.email,
        avatarUrl: avatarUrl ?? currentState.avatarUrl,
      );
    } catch (e) {
      // В случае ошибки обновляем локально
      state = currentState.copyWith(
        name: name ?? currentState.name,
        email: email ?? currentState.email,
        avatarUrl: avatarUrl ?? currentState.avatarUrl,
      );
    }
  }

  Future<void> resetStats() async {
    final currentState = state;

    try {
      final userId = supabase.AppSupabaseClient.instance.currentUserId;
      if (userId != null) {
        await _statsRepo.resetStreak(userId);
        // TODO: Реализовать полный сброс статистики
      }

      state = currentState.copyWith(
        stats: UserStats.initial(),
        workoutHistory: [],
      );
    } catch (e) {
      state = currentState.copyWith(
        stats: UserStats.initial(),
        workoutHistory: [],
      );
    }
  }

  List<WorkoutHistory> getWorkoutHistoryForPeriod(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return state.workoutHistory
        .where((workout) => workout.date.isAfter(cutoffDate))
        .toList();
  }

  String getTopMuscleGroup() {
    if (state.stats.muscleGroupDistribution.isEmpty) {
      return 'Нет данных';
    }
    
    final sorted = state.stats.muscleGroupDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.first.key;
  }

  Map<String, dynamic> getSummaryStats() {
    return {
      'totalWorkouts': state.stats.totalWorkouts,
      'totalMinutes': state.stats.totalMinutes,
      'currentStreak': state.stats.currentStreak,
      'topMuscleGroup': getTopMuscleGroup(),
      'averageWorkoutTime': state.stats.averageWorkoutTime.toStringAsFixed(1),
    };
  }

  /// Сохранение плана тренировок
  /// Теперь использует WorkoutPlanRepository
  Future<void> savePlan(WorkoutPlan plan) async {
    final currentState = state;

    try {
      final userId = supabase.AppSupabaseClient.instance.currentUserId;
      if (userId == null) return;

      // План сохраняется через WorkoutPlanRepository (см. PlannerProvider)
      // Здесь обновляем только локальное состояние для отображения
      final savedPlan = SavedPlan(
        planId: plan.id,
        name: plan.name,
        description: plan.description,
        savedAt: DateTime.now(),
        planCreatedAt: plan.createdAt,
        trainingSystem: plan.trainingSystem?.displayName,
        workoutsCount: plan.workouts.length,
        planData: plan.toJson(),
      );

      final existingIndex = currentState.savedPlans.indexWhere((p) => p.planId == plan.id);
      final updatedPlans = List<SavedPlan>.from(currentState.savedPlans);
      
      if (existingIndex != -1) {
        updatedPlans[existingIndex] = savedPlan;
      } else {
        updatedPlans.add(savedPlan);
      }

      state = currentState.copyWith(savedPlans: updatedPlans);
    } catch (e) {
      // В случае ошибки обновляем локально
      final savedPlan = SavedPlan(
        planId: plan.id,
        name: plan.name,
        description: plan.description,
        savedAt: DateTime.now(),
        planCreatedAt: plan.createdAt,
        trainingSystem: plan.trainingSystem?.displayName,
        workoutsCount: plan.workouts.length,
        planData: plan.toJson(),
      );

      final existingIndex = currentState.savedPlans.indexWhere((p) => p.planId == plan.id);
      final updatedPlans = List<SavedPlan>.from(currentState.savedPlans);
      
      if (existingIndex != -1) {
        updatedPlans[existingIndex] = savedPlan;
      } else {
        updatedPlans.add(savedPlan);
      }

      state = currentState.copyWith(savedPlans: updatedPlans);
    }
  }

  /// Удаление сохраненного плана
  Future<void> deleteSavedPlan(String planId) async {
    final updatedPlans = state.savedPlans.where((p) => p.planId != planId).toList();
    state = state.copyWith(savedPlans: updatedPlans);
  }

  /// Загрузка плана из сохраненных
  WorkoutPlan? loadSavedPlan(String planId) {
    try {
      final savedPlan = state.savedPlans.firstWhere(
        (p) => p.planId == planId,
      );
      return WorkoutPlan.fromJson(savedPlan.planData);
    } catch (e) {
      return null;
    }
  }

  /// Получить все сохраненные планы
  List<SavedPlan> getSavedPlans() {
    return List.from(state.savedPlans);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile>(
  (ref) => ProfileNotifier(),
);