// lib/data/models/exercise_selection_rules.dart
import 'package:fitplan_creator/data/models/exercise.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'package:fitplan_creator/data/models/training_system.dart';

/// Правила для подбора и адаптации упражнений
class ExerciseSelectionRules {
  // Правила замены упражнений по оборудованию (для будущего использования)
  // ignore: unused_field
  static final Map<String, List<String>> _equipmentReplacementMap = {
    // Штанга → Гантели/Тренажеры/Bodyweight
    'barbell': ['dumbbells', 'cable_machine', 'bodyweight', 'kettlebell'],
    'dumbbells': ['barbell', 'cable_machine', 'bodyweight', 'kettlebell'],
    'cable_machine': ['dumbbells', 'barbell', 'resistance_bands'],
    'pull_up_bar': ['parallel_bars', 'suspension_trainer', 'bodyweight'],
    'parallel_bars': ['pull_up_bar', 'bench', 'suspension_trainer'],
    'bench': ['floor', 'exercise_ball', 'bodyweight'],
    'leg_press': ['barbell', 'dumbbells', 'bodyweight'],
    'smith_machine': ['barbell', 'dumbbells', 'bodyweight'],
    'resistance_bands': ['cable_machine', 'dumbbells', 'bodyweight'],
    'kettlebell': ['dumbbells', 'barbell', 'bodyweight'],
    'cardio_equipment': ['bodyweight', 'jump_rope', 'running'],
  };

  // Правила замены по группам мышц
  static final Map<String, List<String>> _muscleGroupExerciseMap = {
    'chest': ['chest_01', 'chest_07', 'chest_08', 'chest_12', 'chest_13', 'chest_14', 'chest_15'],
    'back': ['back_01', 'back_02', 'back_03', 'back_04', 'back_05', 'back_06', 'back_07', 'back_10', 'back_11'],
    'legs': ['legs_01', 'legs_02', 'legs_03', 'legs_04', 'legs_05', 'legs_06', 'legs_07', 'legs_08', 'legs_09', 'legs_10', 'legs_11'],
    'shoulders': ['shoulders_01', 'shoulders_02', 'shoulders_04', 'shoulders_05'],
    'arms': ['arms_01', 'arms_02', 'arms_03', 'arms_05', 'arms_06', 'arms_07', 'arms_08', 'arms_09'],
    'abs': ['abs_01', 'abs_02', 'abs_03', 'abs_04', 'abs_05', 'abs_08'],
    'cardio': ['cardio_01', 'cardio_02', 'cardio_03', 'cardio_04', 'cardio_06', 'cardio_07', 'cardio_08', 'cardio_09'],
  };

  // Противопоказания по здоровью
  static final Map<String, List<String>> _healthContraindications = {
    'back': ['back_10', 'legs_04', 'legs_10'], // Становая тяга, румынская тяга
    'knees': ['legs_01', 'legs_05', 'legs_09', 'cardio_04'], // Приседания, выпады, выпрыгивания
    'shoulders': ['shoulders_05', 'chest_12', 'chest_13', 'arms_05'], // Жим стоя, жим лежа, французский жим
    'neck': ['shoulders_05', 'abs_01', 'abs_03'], // Жим стоя, скручивания, подъем ног
    'wrist': ['chest_01', 'chest_15', 'arms_07', 'arms_08'], // Отжимания, отжимания с хлопком, сгибания
    'elbow': ['arms_05', 'arms_06', 'chest_12'], // Французский жим, разгибания, жим лежа
    'hip': ['legs_01', 'legs_09', 'legs_11'], // Приседания, выпады, мостик
    'high_blood_pressure': ['cardio_03', 'cardio_04', 'cardio_08'], // Берпи, выпрыгивания, скалолаз
    'heart_issues': ['cardio_03', 'cardio_04', 'cardio_08', 'cardio_09'], // Высокоинтенсивные упражнения
  };

  /// Получить альтернативные упражнения на ту же группу мышц
  static List<String> getAlternativeExercisesForMuscleGroup(
    String muscleGroup, 
    List<String> availableExerciseIds,
  ) {
    final exercises = _muscleGroupExerciseMap[muscleGroup.toLowerCase()] ?? [];
    return exercises.where((id) => availableExerciseIds.contains(id)).toList();
  }

  /// Проверить безопасность упражнения для пользователя
  static bool isExerciseSafeForUser(String exerciseId, UserPreferences prefs) {
    // Если нет ограничений по здоровью, упражнение безопасно
    if (prefs.healthRestrictions.isEmpty || 
        prefs.healthRestrictions.any((r) => r.displayName == 'Нет ограничений')) {
      return true;
    }

    // Проверяем каждое ограничение
    for (final restriction in prefs.healthRestrictions) {
      final restrictedExercises = _healthContraindications[restriction.displayName] ?? [];
      if (restrictedExercises.contains(exerciseId)) {
        return false;
      }
    }

    return true;
  }

  /// Получить замену упражнения на основе доступного оборудования
  static List<String> getEquipmentReplacements(
    String exerciseId,
    List<Equipment> availableEquipment,
    List<Exercise> allExercises,
  ) {
    final exercise = allExercises.firstWhere(
      (e) => e.id == exerciseId,
      orElse: () => Exercise.empty(),
    );

    if (exercise.id.isEmpty) return [];

    // Если оборудование доступно, возвращаем само упражнение
    if (_isEquipmentAvailable(exercise, availableEquipment)) {
      return [exerciseId];
    }

    // Ищем альтернативные упражнения
    final alternatives = <String>[];

    // 1. Ищем упражнения на те же группы мышц
    final sameMuscleExercises = allExercises.where((e) {
      if (e.id == exerciseId) return false;
      
      final hasCommonPrimary = exercise.primaryMuscleGroups.any(
        (muscle) => e.primaryMuscleGroups.contains(muscle),
      );
      
      final hasCommonSecondary = exercise.secondaryMuscleGroups.any(
        (muscle) => e.secondaryMuscleGroups.contains(muscle),
      );

      return hasCommonPrimary || hasCommonSecondary;
    }).toList();

    // 2. Фильтруем по доступному оборудованию
    for (final altExercise in sameMuscleExercises) {
      if (_isEquipmentAvailable(altExercise, availableEquipment)) {
        alternatives.add(altExercise.id);
      }
    }

    // 3. Если нет альтернатив, ищем bodyweight упражнения
    if (alternatives.isEmpty) {
      final bodyweightExercises = sameMuscleExercises.where(
        (e) => e.isBodyweight && e.isAvailableWith([]),
      );
      alternatives.addAll(bodyweightExercises.map((e) => e.id).toList());
    }

    return alternatives.take(5).toList(); // Ограничиваем 5 вариантами
  }

  /// Проверить доступность оборудования для упражнения
  static bool _isEquipmentAvailable(
    Exercise exercise, 
    List<Equipment> availableEquipment,
  ) {
    if (exercise.requiredEquipment.isEmpty || exercise.isBodyweight) {
      return true;
    }

    final availableEquipmentNames = availableEquipment.map((e) => e.displayName).toList();
    
    return exercise.requiredEquipment.every(
      (requiredEq) => availableEquipmentNames.contains(requiredEq),
    );
  }

  /// Адаптировать упражнение под уровень пользователя
  static ExerciseTemplate adaptExerciseForUser(
    ExerciseTemplate template,
    ExperienceLevel userLevel,
    UserGoal goal,
    BodyType? bodyType,
  ) {
    int adaptedSets = template.sets;
    int adaptedReps = template.reps;
    int adaptedRestTime = template.restTime;

    // Адаптация по уровню
    switch (userLevel) {
      case ExperienceLevel.beginner:
        adaptedSets = (template.sets * 0.7).ceil().clamp(2, 3);
        adaptedReps = (template.reps * 1.2).ceil().clamp(8, 15);
        adaptedRestTime = (template.restTime * 1.5).ceil().clamp(60, 90);
        break;
      case ExperienceLevel.intermediate:
        adaptedSets = template.sets.clamp(3, 4);
        adaptedReps = template.reps.clamp(6, 12);
        adaptedRestTime = template.restTime.clamp(60, 120);
        break;
      case ExperienceLevel.advanced:
        adaptedSets = (template.sets * 1.2).ceil().clamp(4, 5);
        adaptedReps = (template.reps * 0.8).ceil().clamp(4, 8);
        adaptedRestTime = (template.restTime * 0.8).ceil().clamp(90, 180);
        break;
    }

    // Адаптация по цели
    switch (goal) {
      case UserGoal.weightLoss:
        adaptedSets = adaptedSets.clamp(3, 4);
        adaptedReps = (adaptedReps * 1.3).ceil().clamp(12, 20);
        adaptedRestTime = (adaptedRestTime * 0.7).ceil().clamp(30, 60);
        break;
      case UserGoal.muscleGain:
        adaptedSets = (adaptedSets * 1.1).ceil().clamp(3, 5);
        adaptedReps = adaptedReps.clamp(6, 12);
        adaptedRestTime = adaptedRestTime.clamp(60, 120);
        break;
      case UserGoal.strength:
        adaptedSets = adaptedSets.clamp(4, 6);
        adaptedReps = (adaptedReps * 0.6).ceil().clamp(3, 6);
        adaptedRestTime = (adaptedRestTime * 1.5).ceil().clamp(120, 180);
        break;
      case UserGoal.endurance:
        adaptedSets = adaptedSets.clamp(2, 3);
        adaptedReps = (adaptedReps * 1.5).ceil().clamp(15, 30);
        adaptedRestTime = (adaptedRestTime * 0.5).ceil().clamp(20, 45);
        break;
      case UserGoal.generalFitness:
        // Без изменений
        break;
    }

    // Адаптация по типу телосложения (опционально)
    if (bodyType != null) {
      switch (bodyType) {
        case BodyType.ectomorph:
          // Меньше объем, больше отдых
          adaptedSets = (adaptedSets * 0.9).ceil();
          adaptedRestTime = (adaptedRestTime * 1.1).ceil();
          break;
        case BodyType.mesomorph:
          // Без изменений
          break;
        case BodyType.endomorph:
          // Больше объем, меньше отдых для жиросжигания
          adaptedSets = (adaptedSets * 1.1).ceil();
          adaptedRestTime = (adaptedRestTime * 0.9).ceil();
          break;
      }
    }

    return ExerciseTemplate(
      exerciseId: template.exerciseId,
      sets: adaptedSets,
      reps: adaptedReps,
      restTime: adaptedRestTime,
      isSuperSet: template.isSuperSet,
      tempo: template.tempo,
      rpe: template.rpe,
      notes: template.notes,
    );
  }

  /// Получить приоритет упражнения для пользователя
  static double getExercisePriority(
    String exerciseId,
    UserPreferences prefs,
    List<String> favoriteMuscleGroups,
  ) {
    double priority = 1.0;

    final exercise = Exercise.empty(); // Здесь нужно получить реальное упражнение

    // Увеличиваем приоритет для любимых групп мышц
    final primaryInFavorites = exercise.primaryMuscleGroups.any(
      (muscle) => favoriteMuscleGroups.contains(muscle),
    );
    
    final secondaryInFavorites = exercise.secondaryMuscleGroups.any(
      (muscle) => favoriteMuscleGroups.contains(muscle),
    );

    if (primaryInFavorites) priority *= 1.5;
    if (secondaryInFavorites) priority *= 1.2;

    // Уменьшаем приоритет для нелюбимых упражнений
    if (prefs.dislikedExercises.any((disliked) => 
        exercise.name.toLowerCase().contains(disliked.toLowerCase()))) {
      priority *= 0.3;
    }

    // Адаптация под уровень сложности
    switch (prefs.experienceLevel) {
      case ExperienceLevel.beginner:
        if (exercise.difficulty == ExerciseDifficulty.beginner) priority *= 1.3;
        if (exercise.difficulty == ExerciseDifficulty.advanced) priority *= 0.5;
        break;
      case ExperienceLevel.intermediate:
        if (exercise.difficulty == ExerciseDifficulty.intermediate) priority *= 1.2;
        break;
      case ExperienceLevel.advanced:
        if (exercise.difficulty == ExerciseDifficulty.advanced) priority *= 1.3;
        if (exercise.difficulty == ExerciseDifficulty.beginner) priority *= 0.7;
        break;
      default:
        break;
    }

    return priority;
  }

  /// Проверить, соответствует ли упражнение системе тренировок
  static bool isExerciseCompatibleWithSystem(
    String exerciseId,
    TrainingSystem system,
    int dayNumber,
    String dayFocus,
  ) {
    // Правила для каждой системы
    switch (system) {
      case TrainingSystem.fullBody:
        // На каждый день - полное тело, большинство упражнений подходят
        return true;

      case TrainingSystem.split:
        // Зависит от дня и фокуса
        switch (dayFocus.toLowerCase()) {
          case 'chest':
          case 'triceps':
            return exerciseId.startsWith('chest_') || exerciseId.startsWith('arms_');
          case 'back':
          case 'biceps':
            return exerciseId.startsWith('back_') || exerciseId.startsWith('arms_');
          case 'legs':
          case 'shoulders':
            return exerciseId.startsWith('legs_') || exerciseId.startsWith('shoulders_');
          default:
            return true;
        }

      case TrainingSystem.ppl:
        // Push/Pull/Legs разделение
        switch (dayFocus.toLowerCase()) {
          case 'push':
            return exerciseId.startsWith('chest_') || 
                   exerciseId.startsWith('shoulders_') || 
                   exerciseId.startsWith('arms_05') || exerciseId.startsWith('arms_06');
          case 'pull':
            return exerciseId.startsWith('back_') || 
                   exerciseId.startsWith('arms_01') || exerciseId.startsWith('arms_02') || 
                   exerciseId.startsWith('arms_07');
          case 'legs':
            return exerciseId.startsWith('legs_') || exerciseId.startsWith('abs_');
          default:
            return true;
        }

      case TrainingSystem.upperLower:
        // Верх/Низ разделение
        switch (dayFocus.toLowerCase()) {
          case 'upper':
            return exerciseId.startsWith('chest_') || 
                   exerciseId.startsWith('back_') || 
                   exerciseId.startsWith('shoulders_') || 
                   exerciseId.startsWith('arms_');
          case 'lower':
            return exerciseId.startsWith('legs_') || exerciseId.startsWith('abs_');
          default:
            return true;
        }

      case TrainingSystem.circuit:
        // Круговые тренировки - в основном кардио и функциональные
        return exerciseId.startsWith('cardio_') || 
               exerciseId.startsWith('abs_') ||
               exerciseId.contains('burpee') ||
               exerciseId.contains('jump');

      case TrainingSystem.cardio:
        // Только кардио упражнения
        return exerciseId.startsWith('cardio_');
    }
  }

  /// Балансировка нагрузки по мышечным группам
  static Map<String, int> calculateMuscleGroupBalance(List<ExerciseTemplate> exercises) {
    final balance = <String, int>{};

    // Группы мышц
    final muscleGroups = [
      'chest', 'back', 'legs', 'shoulders', 'biceps', 'triceps', 'abs', 'cardio'
    ];

    for (final group in muscleGroups) {
      balance[group] = 0;
    }

    // Подсчитываем нагрузку (грубо по ID упражнений)
    for (final exercise in exercises) {
      if (exercise.exerciseId.startsWith('chest_')) balance['chest'] = balance['chest']! + 1;
      else if (exercise.exerciseId.startsWith('back_')) balance['back'] = balance['back']! + 1;
      else if (exercise.exerciseId.startsWith('legs_')) balance['legs'] = balance['legs']! + 1;
      else if (exercise.exerciseId.startsWith('shoulders_')) balance['shoulders'] = balance['shoulders']! + 1;
      else if (exercise.exerciseId.contains('biceps') || exercise.exerciseId.startsWith('arms_01') || 
               exercise.exerciseId.startsWith('arms_02') || exercise.exerciseId.startsWith('arms_07')) {
        balance['biceps'] = balance['biceps']! + 1;
      }
      else if (exercise.exerciseId.contains('triceps') || exercise.exerciseId.startsWith('arms_05') || 
               exercise.exerciseId.startsWith('arms_06') || exercise.exerciseId.startsWith('arms_08')) {
        balance['triceps'] = balance['triceps']! + 1;
      }
      else if (exercise.exerciseId.startsWith('abs_')) balance['abs'] = balance['abs']! + 1;
      else if (exercise.exerciseId.startsWith('cardio_')) balance['cardio'] = balance['cardio']! + 1;
    }

    return balance;
  }

  /// Проверить сбалансированность тренировки
  static bool isWorkoutBalanced(Map<String, int> muscleBalance, TrainingSystem system) {
    // Разные критерии для разных систем
    switch (system) {
      case TrainingSystem.fullBody:
        // Полное тело должно иметь хотя бы по одному упражнению на основные группы
        final mainGroups = ['chest', 'back', 'legs'];
        return mainGroups.every((group) => (muscleBalance[group] ?? 0) >= 1);

      case TrainingSystem.split:
        // Сплит должен фокусироваться на 1-2 группах в день
        final nonZeroGroups = muscleBalance.values.where((count) => count > 0).length;
        return nonZeroGroups <= 3;

      case TrainingSystem.ppl:
        // PPL: Push - толкающие, Pull - тянущие, Legs - ноги
        return true;

      case TrainingSystem.upperLower:
        // Верх/Низ должно быть четкое разделение
        final upperGroups = ['chest', 'back', 'shoulders', 'biceps', 'triceps'];
        final lowerGroups = ['legs', 'abs'];
        
        final upperCount = upperGroups.fold(0, (sum, group) => sum + (muscleBalance[group] ?? 0));
        final lowerCount = lowerGroups.fold(0, (sum, group) => sum + (muscleBalance[group] ?? 0));
        
        return (upperCount == 0 && lowerCount > 0) || (upperCount > 0 && lowerCount == 0);

      case TrainingSystem.circuit:
        // Круговые тренировки могут включать всё
        return muscleBalance.values.fold(0, (sum, count) => sum + count) >= 4;

      case TrainingSystem.cardio:
        // Кардио тренировки должны быть в основном кардио
        final cardioCount = muscleBalance['cardio'] ?? 0;
        final totalCount = muscleBalance.values.fold(0, (sum, count) => sum + count);
        return totalCount > 0 && cardioCount >= totalCount * 0.7;
    }
  }
}