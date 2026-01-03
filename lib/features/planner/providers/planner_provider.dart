import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart'; // Добавь этот импорт
import 'package:fitplan_creator/data/models/workout_plan.dart';
import 'package:fitplan_creator/data/models/workout_exercise.dart';
import 'package:fitplan_creator/data/repositories/workout_repository.dart';
import 'package:fitplan_creator/data/repositories/workout_repository_provider.dart';

final plannerProvider = StateNotifierProvider<PlannerNotifier, WorkoutPlan?>((ref) {
  final repository = ref.watch(workoutRepositoryProvider);
  return PlannerNotifier(repository);
});

class PlannerNotifier extends StateNotifier<WorkoutPlan?> {
  final WorkoutRepository _repository;

  PlannerNotifier(this._repository) : super(null);

  Future<void> generatePlan({
    required String userId,
    required String goal,
    required String level,
    required List<String> equipment,
  }) async {
    try {
      final preferences = UserPreferences( // Теперь этот класс доступен
        goal: goal,
        level: level,
        equipment: equipment,
      );
      
      final plan = await _repository.createUserPlan(
        userId: userId,
        preferences: preferences,
      );
      
      state = plan;
    } catch (e) {
      // Обработка ошибки
      rethrow;
    }
  }

  void updateExercise(String dayId, int exerciseIndex, String newExerciseId) {
    if (state == null) return;

    final updatedPlan = WorkoutPlan(
      id: state!.id,
      userId: state!.userId,
      templateId: state!.templateId,
      weeklyPlan: Map.from(state!.weeklyPlan),
      createdAt: state!.createdAt,
    );

    final exercises = updatedPlan.weeklyPlan[dayId];
    if (exercises != null && exerciseIndex < exercises.length) {
      final updatedExercises = List<WorkoutExercise>.from(exercises);
      updatedExercises[exerciseIndex] = WorkoutExercise(
        exerciseId: newExerciseId,
        sets: exercises[exerciseIndex].sets,
        reps: exercises[exerciseIndex].reps,
      );
      
      updatedPlan.weeklyPlan[dayId] = updatedExercises;
      state = updatedPlan;
    }
  }

  void savePlan() async {
    // TODO: Реализовать сохранение в Firebase
    if (state != null) {
      // await _repository.savePlan(state!);
    }
  }
}