// lib/features/profile/providers/profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';

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
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile>(
  (ref) => ProfileNotifier(),
);