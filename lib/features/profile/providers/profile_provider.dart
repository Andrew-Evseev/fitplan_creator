// lib/features/profile/providers/profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import 'package:fitplan_creator/data/models/workout_plan.dart';

class ProfileNotifier extends StateNotifier<UserProfile> {
  ProfileNotifier() : super(_initialProfile());

  static UserProfile _initialProfile() {
    return UserProfile.initial('user_001', 'Пользователь');
  }

  // Обновление статистики при завершении тренировки
  void updateStatsAfterWorkout({
    required int duration,
    required int exercisesCount,
    required Map<String, int> muscleGroups,
  }) {
    final now = DateTime.now();
    final lastWorkoutDate = state.workoutHistory.isNotEmpty
        ? state.workoutHistory.last.date
        : DateTime(0);
    
    final daysSinceLastWorkout = now.difference(lastWorkoutDate).inDays;
    int newStreak = state.stats.currentStreak;
    
    if (daysSinceLastWorkout <= 1) {
      newStreak++;
    } else {
      newStreak = 1;
    }

    final newMaxStreak = newStreak > state.stats.maxStreak
        ? newStreak
        : state.stats.maxStreak;

    final updatedDistribution = Map<String, int>.from(state.stats.muscleGroupDistribution);
    muscleGroups.forEach((muscle, count) {
      updatedDistribution[muscle] = (updatedDistribution[muscle] ?? 0) + count;
    });

    final newTotalWorkouts = state.stats.totalWorkouts + 1;
    final newAverageTime = (state.stats.totalMinutes + duration) / newTotalWorkouts;

    state = state.copyWith(
      stats: state.stats.copyWith(
        totalWorkouts: newTotalWorkouts,
        totalExercises: state.stats.totalExercises + exercisesCount,
        totalMinutes: state.stats.totalMinutes + duration,
        currentStreak: newStreak,
        maxStreak: newMaxStreak,
        muscleGroupDistribution: updatedDistribution,
        averageWorkoutTime: newAverageTime,
      ),
      workoutHistory: [
        ...state.workoutHistory,
        WorkoutHistory(
          id: 'workout_${DateTime.now().millisecondsSinceEpoch}',
          planName: 'Тренировка ${state.stats.totalWorkouts + 1}',
          date: now,
          duration: duration,
          exercisesCount: exercisesCount,
          completed: true,
        ),
      ],
    );
  }

  void updateSettings(UserSettings newSettings) {
    state = state.copyWith(settings: newSettings);
  }

  void updateProfile({
    String? name,
    String? email,
    String? avatarUrl,
  }) {
    state = state.copyWith(
      name: name ?? state.name,
      email: email ?? state.email,
      avatarUrl: avatarUrl ?? state.avatarUrl,
    );
  }

  void resetStats() {
    state = state.copyWith(
      stats: UserStats.initial(),
      workoutHistory: [],
    );
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

  // Сохранение плана тренировок
  void savePlan(WorkoutPlan plan) {
    // Проверяем, не сохранен ли уже этот план
    final existingIndex = state.savedPlans.indexWhere((p) => p.planId == plan.id);
    
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

    final updatedPlans = List<SavedPlan>.from(state.savedPlans);
    
    if (existingIndex != -1) {
      // Обновляем существующий план
      updatedPlans[existingIndex] = savedPlan;
    } else {
      // Добавляем новый план
      updatedPlans.add(savedPlan);
    }

    state = state.copyWith(savedPlans: updatedPlans);
  }

  // Удаление сохраненного плана
  void deleteSavedPlan(String planId) {
    final updatedPlans = state.savedPlans.where((p) => p.planId != planId).toList();
    state = state.copyWith(savedPlans: updatedPlans);
  }

  // Загрузка плана из сохраненных
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

  // Получить все сохраненные планы
  List<SavedPlan> getSavedPlans() {
    return List.from(state.savedPlans);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile>(
  (ref) => ProfileNotifier(),
);