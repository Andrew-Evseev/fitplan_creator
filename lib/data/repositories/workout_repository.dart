import 'package:fitplan_creator/data/models/exercise.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'package:fitplan_creator/data/models/workout_plan.dart';
import 'package:fitplan_creator/data/models/workout_template.dart';
import 'package:fitplan_creator/data/models/workout_exercise.dart';

class WorkoutRepository {
  List<Exercise> getAllExercises() {
    return [
      const Exercise(
        id: 'pushup',
        name: 'Отжимания',
        description: 'Базовое упражнение для груди и трицепса',
        instructions: 'Примите упор лежа...',
        primaryMuscleGroup: 'chest',
        secondaryMuscleGroups: ['triceps', 'shoulders'],
        requiredEquipment: [],
        difficulty: 'beginner',
      ),
      const Exercise(
        id: 'squat',
        name: 'Приседания',
        description: 'Базовое упражнение для ног',
        instructions: 'Встаньте прямо...',
        primaryMuscleGroup: 'legs',
        secondaryMuscleGroups: ['glutes', 'core'],
        requiredEquipment: [],
        difficulty: 'beginner',
      ),
      const Exercise(
        id: 'plank',
        name: 'Планка',
        description: 'Упражнение для укрепления кора',
        instructions: 'Примите положение упора лежа на предплечьях...',
        primaryMuscleGroup: 'core',
        secondaryMuscleGroups: ['shoulders', 'back'],
        requiredEquipment: [],
        difficulty: 'beginner',
      ),
      const Exercise(
        id: 'dumbbell_curl',
        name: 'Сгибания рук с гантелями',
        description: 'Упражнение для бицепса',
        instructions: 'Возьмите гантели в обе руки...',
        primaryMuscleGroup: 'biceps',
        secondaryMuscleGroups: ['forearms'],
        requiredEquipment: ['dumbbells'],
        difficulty: 'beginner',
      ),
      const Exercise(
        id: 'dumbbell_press',
        name: 'Жим гантелей',
        description: 'Упражнение для груди и плеч',
        instructions: 'Лягте на скамью...',
        primaryMuscleGroup: 'chest',
        secondaryMuscleGroups: ['shoulders', 'triceps'],
        requiredEquipment: ['dumbbells', 'bench'],
        difficulty: 'intermediate',
      ),
    ];
  }

  WorkoutPlan getWorkoutPlan({UserPreferences? preferences}) {
    // Создаем упражнения для тренировок
    final day1Exercises = [
      WorkoutExercise(exerciseId: 'pushup', sets: 3, reps: 10),
      WorkoutExercise(exerciseId: 'plank', sets: 3, reps: 30),
    ];
    
    final day2Exercises = [
      WorkoutExercise(exerciseId: 'squat', sets: 3, reps: 12),
      WorkoutExercise(exerciseId: 'plank', sets: 3, reps: 30),
    ];

    // Создаем тренировки
    final workouts = [
      Workout(
        id: 'day1',
        name: 'День 1: Верх тела',
        dayOfWeek: 1,
        exercises: day1Exercises,
        duration: 45,
        completed: false,
      ),
      Workout(
        id: 'day2',
        name: 'День 2: Низ тела',
        dayOfWeek: 2,
        exercises: day2Exercises,
        duration: 45,
        completed: false,
      ),
    ];

    return WorkoutPlan(
      id: 'default',
      userId: 'default',
      name: preferences?.goal != null ? 'План для ${preferences!.goal!.displayName}' : 'План тренировок',
      description: 'Персональный план',
      workouts: workouts,
      createdAt: DateTime.now(),
      userPreferences: preferences,
    );
  }

  List<WorkoutTemplate> getWorkoutTemplates() {
    final fullbodyExercises = [
      WorkoutExercise(exerciseId: 'squat', sets: 3, reps: 10),
      WorkoutExercise(exerciseId: 'pushup', sets: 3, reps: 12),
      WorkoutExercise(exerciseId: 'plank', sets: 3, reps: 30),
    ];
    
    final cardioExercises = [
      WorkoutExercise(exerciseId: 'pushup', sets: 3, reps: 15),
      WorkoutExercise(exerciseId: 'plank', sets: 4, reps: 45),
    ];

    return [
      WorkoutTemplate(
        id: 'fullbody',
        name: 'Фулбади',
        description: 'Тренировка на все тело',
        exercises: fullbodyExercises,
        duration: 60,
        difficulty: 'beginner',
      ),
      WorkoutTemplate(
        id: 'cardio',
        name: 'Кардио',
        description: 'Тренировка для выносливости',
        exercises: cardioExercises,
        duration: 30,
        difficulty: 'beginner',
      ),
    ];
  }
}