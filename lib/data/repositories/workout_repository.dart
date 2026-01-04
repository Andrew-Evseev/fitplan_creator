import 'package:fitplan_creator/data/models/exercise.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'package:fitplan_creator/data/models/workout_plan.dart';
import 'package:fitplan_creator/data/models/workout_template.dart';
import 'package:fitplan_creator/data/models/workout_exercise.dart';

class WorkoutRepository {
  List<Exercise> getAllExercises() {
    return [
      // Упражнения для груди
      const Exercise(
        id: 'pushup',
        name: 'Отжимания',
        description: 'Базовое упражнение для грудных мышц и трицепсов',
        instructions: '1. Примите упор лежа...',
        primaryMuscleGroup: 'chest',
        secondaryMuscleGroups: ['triceps', 'shoulders'],
        requiredEquipment: [],
        difficulty: 'beginner',
        imageUrl: 'assets/exercises/push_up.gif',
      ),
      const Exercise(
        id: 'bench_press',
        name: 'Жим штанги лежа',
        description: 'Базовое упражнение для развития грудных мышц',
        instructions: '1. Лягте на скамью...',
        primaryMuscleGroup: 'chest',
        secondaryMuscleGroups: ['triceps', 'shoulders'],
        requiredEquipment: ['barbell', 'bench'],
        difficulty: 'intermediate',
        imageUrl: 'assets/exercises/bench_press.gif',
      ),
      const Exercise(
        id: 'dumbbell_press',
        name: 'Жим гантелей лежа',
        description: 'Упражнение для грудных мышц с большей амплитудой',
        instructions: '1. Лягте на скамью с гантелями...',
        primaryMuscleGroup: 'chest',
        secondaryMuscleGroups: ['shoulders', 'triceps'],
        requiredEquipment: ['dumbbells', 'bench'],
        difficulty: 'intermediate',
        imageUrl: 'assets/exercises/dumbbell_bench_press.gif',
      ),
      const Exercise(
        id: 'chest_fly',
        name: 'Сведение гантелей лежа',
        description: 'Изолирующее упражнение для грудных мышц',
        instructions: '1. Лягте на скамью...',
        primaryMuscleGroup: 'chest',
        secondaryMuscleGroups: [],
        requiredEquipment: ['dumbbells', 'bench'],
        difficulty: 'intermediate',
        imageUrl: 'assets/exercises/chest_fly.gif',
      ),

      // Упражнения для спины
      const Exercise(
        id: 'pull_up',
        name: 'Подтягивания',
        description: 'Базовое упражнение для широчайших мышц спины',
        instructions: '1. Возьмитесь за турник...',
        primaryMuscleGroup: 'back',
        secondaryMuscleGroups: ['biceps'],
        requiredEquipment: ['pullUpBar'],
        difficulty: 'intermediate',
        imageUrl: 'assets/exercises/pull_up.gif',
      ),
      const Exercise(
        id: 'barbell_row',
        name: 'Тяга штанги в наклоне',
        description: 'Упражнение для толщины спины',
        instructions: '1. Наклонитесь вперед...',
        primaryMuscleGroup: 'back',
        secondaryMuscleGroups: ['biceps'],
        requiredEquipment: ['barbell'],
        difficulty: 'intermediate',
        imageUrl: 'assets/exercises/barbell_row.gif',
      ),
      const Exercise(
        id: 'lat_pulldown',
        name: 'Тяга верхнего блока',
        description: 'Аналог подтягиваний в тренажере',
        instructions: '1. Сядьте в тренажер...',
        primaryMuscleGroup: 'back',
        secondaryMuscleGroups: ['biceps'],
        requiredEquipment: ['cableMachine'],
        difficulty: 'beginner',
        imageUrl: 'assets/exercises/lat_pulldown.gif',
      ),
      const Exercise(
        id: 'deadlift',
        name: 'Становая тяга',
        description: 'Базовое упражнение для всей задней поверхности тела',
        instructions: '1. Встаньте перед штангой...',
        primaryMuscleGroup: 'back',
        secondaryMuscleGroups: ['hamstrings', 'glutes'],
        requiredEquipment: ['barbell'],
        difficulty: 'advanced',
        imageUrl: 'assets/exercises/deadlift.gif',
      ),

      // Упражнения для ног
      const Exercise(
        id: 'squat',
        name: 'Приседания со штангой',
        description: 'Базовое упражнение для развития мышц ног',
        instructions: '1. Поместите штангу на трапеции...',
        primaryMuscleGroup: 'legs',
        secondaryMuscleGroups: ['glutes', 'core'],
        requiredEquipment: ['barbell'],
        difficulty: 'intermediate',
        imageUrl: 'assets/exercises/squat.gif',
      ),
      const Exercise(
        id: 'lunges',
        name: 'Выпады с гантелями',
        description: 'Упражнение для ног и ягодиц',
        instructions: '1. Встаньте прямо с гантелями...',
        primaryMuscleGroup: 'legs',
        secondaryMuscleGroups: ['glutes'],
        requiredEquipment: ['dumbbells'],
        difficulty: 'beginner',
        imageUrl: 'assets/exercises/lunges.gif',
      ),
      const Exercise(
        id: 'leg_press',
        name: 'Жим ногами',
        description: 'Упражнение для ног в тренажере',
        instructions: '1. Сядьте в тренажер...',
        primaryMuscleGroup: 'legs',
        secondaryMuscleGroups: ['glutes'],
        requiredEquipment: ['legPressMachine'],
        difficulty: 'beginner',
        imageUrl: 'assets/exercises/leg_press.gif',
      ),
      const Exercise(
        id: 'calf_raise',
        name: 'Подъем на носки стоя',
        description: 'Упражнение для икроножных мышц',
        instructions: '1. Встаньте на платформу...',
        primaryMuscleGroup: 'calves',
        secondaryMuscleGroups: [],
        requiredEquipment: ['calfMachine', 'dumbbells'],
        difficulty: 'beginner',
        imageUrl: 'assets/exercises/calf_raise.gif',
      ),

      // Упражнения для плеч
      const Exercise(
        id: 'overhead_press',
        name: 'Армейский жим',
        description: 'Базовое упражнение для плеч',
        instructions: '1. Возьмите штангу на грудь...',
        primaryMuscleGroup: 'shoulders',
        secondaryMuscleGroups: ['triceps'],
        requiredEquipment: ['barbell'],
        difficulty: 'intermediate',
        imageUrl: 'assets/exercises/overhead_press.gif',
      ),
      const Exercise(
        id: 'lateral_raise',
        name: 'Разведения гантелей в стороны',
        description: 'Упражнение для средних пучков дельт',
        instructions: '1. Встаньте прямо с гантелями...',
        primaryMuscleGroup: 'shoulders',
        secondaryMuscleGroups: [],
        requiredEquipment: ['dumbbells'],
        difficulty: 'beginner',
        imageUrl: 'assets/exercises/dumbbell_lateral_raise.gif',
      ),
      const Exercise(
        id: 'upright_row',
        name: 'Тяга штанги к подбородку',
        description: 'Упражнение для трапеций и дельт',
        instructions: '1. Возьмите штангу узким хватом...',
        primaryMuscleGroup: 'shoulders',
        secondaryMuscleGroups: ['traps'],
        requiredEquipment: ['barbell'],
        difficulty: 'intermediate',
        imageUrl: 'assets/exercises/upright_row.gif',
      ),

      // Упражнения для рук
      const Exercise(
        id: 'bicep_curl',
        name: 'Сгибания рук с гантелями',
        description: 'Упражнение для бицепсов',
        instructions: '1. Встаньте прямо с гантелями...',
        primaryMuscleGroup: 'biceps',
        secondaryMuscleGroups: [],
        requiredEquipment: ['dumbbells'],
        difficulty: 'beginner',
        imageUrl: 'assets/exercises/bicep_curl.gif',
      ),
      const Exercise(
        id: 'triceps_extension',
        name: 'Французский жим',
        description: 'Упражнение для трицепсов',
        instructions: '1. Лягте на скамью со штангой...',
        primaryMuscleGroup: 'triceps',
        secondaryMuscleGroups: [],
        requiredEquipment: ['barbell', 'bench'],
        difficulty: 'intermediate',
        imageUrl: 'assets/exercises/triceps_extension.gif',
      ),
      const Exercise(
        id: 'dips',
        name: 'Отжимания на брусьях',
        description: 'Упражнение для грудных мышц и трицепсов',
        instructions: '1. Упритесь в брусья...',
        primaryMuscleGroup: 'triceps',
        secondaryMuscleGroups: ['chest'],
        requiredEquipment: ['dipBar'],
        difficulty: 'intermediate',
        imageUrl: 'assets/exercises/dips.gif',
      ),

      // Упражнения для пресса
      const Exercise(
        id: 'crunch',
        name: 'Скручивания',
        description: 'Упражнение для прямой мышцы живота',
        instructions: '1. Лягте на спину...',
        primaryMuscleGroup: 'core',
        secondaryMuscleGroups: [],
        requiredEquipment: [],
        difficulty: 'beginner',
        imageUrl: 'assets/exercises/crunch.gif',
      ),
      const Exercise(
        id: 'plank',
        name: 'Планка',
        description: 'Упражнение для укрепления кора',
        instructions: '1. Примите положение упора лежа на предплечьях...',
        primaryMuscleGroup: 'core',
        secondaryMuscleGroups: ['shoulders', 'back'],
        requiredEquipment: [],
        difficulty: 'beginner',
        imageUrl: 'assets/exercises/plank.gif',
      ),
      const Exercise(
        id: 'hanging_leg_raise',
        name: 'Подъем ног в висе',
        description: 'Упражнение для нижней части пресса',
        instructions: '1. Повисните на турнике...',
        primaryMuscleGroup: 'core',
        secondaryMuscleGroups: [],
        requiredEquipment: ['pullUpBar'],
        difficulty: 'intermediate',
        imageUrl: 'assets/exercises/hanging_leg_raise.gif',
      ),

      // Упражнения с собственным весом
      const Exercise(
        id: 'bodyweight_squat',
        name: 'Приседания с собственным весом',
        description: 'Базовое упражнение для ног без оборудования',
        instructions: '1. Встаньте прямо...',
        primaryMuscleGroup: 'legs',
        secondaryMuscleGroups: ['glutes'],
        requiredEquipment: [],
        difficulty: 'beginner',
        imageUrl: 'assets/exercises/bodyweight_squat.gif',
      ),
      const Exercise(
        id: 'burpee',
        name: 'Берпи',
        description: 'Функциональное упражнение для всего тела',
        instructions: '1. Из положения стоя присядьте...',
        primaryMuscleGroup: 'fullBody',
        secondaryMuscleGroups: [],
        requiredEquipment: [],
        difficulty: 'intermediate',
        imageUrl: 'assets/exercises/burpee.gif',
      ),
    ];
  }

  // Новый метод: получение упражнения по ID
  Exercise getExerciseById(String exerciseId) {
    return getAllExercises().firstWhere(
      (exercise) => exercise.id == exerciseId,
      orElse: () => Exercise.empty(),
    );
  }

  // Новый метод: поиск альтернативных упражнений
  List<Exercise> findAlternativeExercises(
    String currentExerciseId,
    List<Equipment> availableEquipment,
  ) {
    final currentExercise = getExerciseById(currentExerciseId);
    if (currentExercise.id.isEmpty) return [];

    final allExercises = getAllExercises();
    
    return allExercises.where((exercise) {
      // Исключаем текущее упражнение
      if (exercise.id == currentExerciseId) return false;
      
      // Проверяем, что оборудование доступно
      final equipmentAvailable = exercise.requiredEquipment.every(
        (requiredEq) => availableEquipment.any(
          (availEq) => availEq.name == requiredEq,
        ),
      );
      if (!equipmentAvailable) return false;
      
      // Ищем упражнения на ту же группу мышц
      return exercise.primaryMuscleGroup == currentExercise.primaryMuscleGroup ||
          exercise.secondaryMuscleGroups.contains(currentExercise.primaryMuscleGroup) ||
          currentExercise.secondaryMuscleGroups.contains(exercise.primaryMuscleGroup);
    }).toList();
  }

  // Существующие методы (оставляем без изменений)
  WorkoutPlan getWorkoutPlan({UserPreferences? preferences}) {
    // ... существующий код ...
    final day1Exercises = [
      WorkoutExercise(exerciseId: 'pushup', sets: 3, reps: 10),
      WorkoutExercise(exerciseId: 'plank', sets: 3, reps: 30),
    ];
    
    final day2Exercises = [
      WorkoutExercise(exerciseId: 'squat', sets: 3, reps: 12),
      WorkoutExercise(exerciseId: 'plank', sets: 3, reps: 30),
    ];

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
    // ... существующий код ...
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