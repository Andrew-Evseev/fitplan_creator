// lib/features/planner/algorithms/plan_generator.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'package:fitplan_creator/data/models/workout_plan.dart';
import 'package:fitplan_creator/data/models/workout_exercise.dart';
import 'package:fitplan_creator/data/models/exercise.dart';
import 'package:fitplan_creator/data/models/training_system.dart';
import 'package:fitplan_creator/data/repositories/training_system_repository.dart';
import 'package:fitplan_creator/data/repositories/workout_repository.dart';
import 'package:fitplan_creator/data/models/exercise_selection_rules.dart';

/// Интеллектуальный генератор тренировочных планов
class PlanGenerator {
  final TrainingSystemRepository _systemRepository;
  final WorkoutRepository _workoutRepository;
  
  // Кэш для сгенерированных планов
  final Map<String, WorkoutPlan> _planCache = {};
  
  // Кэш для упражнений по оборудованию
  final Map<String, List<Exercise>> _equipmentExerciseCache = {};
  
  // Кэш для доступных упражнений
  List<Exercise>? _allExercisesCache;

  PlanGenerator(this._systemRepository, this._workoutRepository);

  /// Основной метод генерации плана
  Future<WorkoutPlan> generatePlan(UserPreferences prefs) async {
    try {
      // Проверяем кэш
      final cacheKey = _generateCacheKey(prefs);
      if (_planCache.containsKey(cacheKey)) {
        final cachedPlan = _planCache[cacheKey];
        if (cachedPlan != null) {
          // Возвращаем копию с новым ID и временем создания
          return cachedPlan.copyWith(
            id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
            createdAt: DateTime.now(),
          );
        }
      }
      
      // 1. Выбор системы тренировок
      final systemTemplate = _selectTrainingSystem(prefs);
      if (systemTemplate.weeklyStructure.isEmpty) {
        throw Exception('Выбранная система тренировок не имеет структуры');
      }
      
      // 2. Адаптация системы под пользователя
      final adaptedSystem = _systemRepository.adaptSystemForUser(systemTemplate, prefs);
      if (adaptedSystem.weeklyStructure.isEmpty) {
        throw Exception('Адаптированная система не имеет структуры');
      }
      
      // 3. Создание тренировочного плана
      final workouts = await _createWorkoutsFromSystem(adaptedSystem, prefs);
      if (workouts.isEmpty) {
        throw Exception('Не удалось создать тренировки');
      }
      
      // 4. Генерация объяснения выбора плана
      final explanation = _generatePlanExplanation(systemTemplate, prefs);
      
      // 5. Создание финального плана
      final plan = WorkoutPlan(
        id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user_${prefs.hashCode}',
        name: _generatePlanName(systemTemplate.system, prefs),
        description: _generatePlanDescription(systemTemplate, prefs),
        workouts: workouts,
        createdAt: DateTime.now(),
        userPreferences: prefs,
        trainingSystem: systemTemplate.system,
        metadata: {
          'explanation': explanation,
          'systemSelectionReason': _getSystemSelectionReason(systemTemplate.system, prefs),
        },
      );
      
      // Сохраняем в кэш (ограничиваем размер кэша до 10 планов)
      if (_planCache.length >= 10) {
        final firstKey = _planCache.keys.first;
        _planCache.remove(firstKey);
      }
      _planCache[cacheKey] = plan;
      
      return plan;
    } catch (e, stackTrace) {
      debugPrint('Ошибка при генерации плана: $e');
      debugPrint('Stack trace: $stackTrace');
      // В случае ошибки возвращаем план по умолчанию
      return _generateFallbackPlan(prefs);
    }
  }

  /// Генерация ключа кэша на основе предпочтений пользователя
  String _generateCacheKey(UserPreferences prefs) {
    final parts = <String>[];
    if (prefs.preferredSystem != null) {
      parts.add(prefs.preferredSystem?.displayName ?? 'none');
    }
    if (prefs.goal != null) {
      parts.add(prefs.goal?.displayName ?? 'none');
    }
    if (prefs.experienceLevel != null) {
      parts.add(prefs.experienceLevel?.displayName ?? 'none');
    }
    if (prefs.daysPerWeek != null) {
      parts.add('days_${prefs.daysPerWeek}');
    }
    if (prefs.trainingLocation != null) {
      parts.add(prefs.trainingLocation?.displayName ?? 'none');
    }
    parts.add(prefs.availableEquipment.map((e) => e.displayName).join(','));
    return parts.join('_');
  }

  /// Выбор системы тренировок на основе предпочтений
  TrainingSystemTemplate _selectTrainingSystem(UserPreferences prefs) {
    // 1. Если пользователь выбрал систему - используем ее
    if (prefs.preferredSystem != null) {
      final selectedSystem = _systemRepository.getSystemByType(prefs.preferredSystem!);
      if (selectedSystem != null && selectedSystem.isCompatibleWith(prefs)) {
        return selectedSystem;
      }
    }

    // 2. Автоматический выбор на основе алгоритма
    final recommendedSystems = _systemRepository.getRecommendedSystems(prefs);
    
    if (recommendedSystems.isNotEmpty) {
      return recommendedSystems.first;
    }

    // 3. Если нет рекомендованных систем, ищем системы по цели (более мягкая проверка)
    if (prefs.goal != null) {
      final systemsByGoal = _systemRepository.getSystemsByGoal(prefs.goal!);
      if (systemsByGoal.isNotEmpty) {
        // Для новичков выбираем системы, которые подходят для начинающих
        if (prefs.experienceLevel == ExperienceLevel.beginner) {
          final beginnerSystems = systemsByGoal.where((s) => 
            s.minExperienceLevel == ExperienceLevel.beginner ||
            s.compatibleLevels.contains(ExperienceLevel.beginner)
          ).toList();
          if (beginnerSystems.isNotEmpty) {
            return beginnerSystems.first;
          }
        }
        // Для среднего и продвинутого уровня берем первую подходящую
        return systemsByGoal.first;
      }
    }

    // 4. Fallback - Full Body для новичков (с проверкой на null)
    final fallbackSystem = _systemRepository.getSystemByType(TrainingSystem.fullBody);
    if (fallbackSystem != null) {
      return fallbackSystem;
    }
    
    // 5. Последний fallback - берем первую доступную систему
    final allSystems = _systemRepository.getAllSystems();
    if (allSystems.isNotEmpty) {
      return allSystems.first;
    }
    
    // 6. Если ничего не найдено - создаем минимальную систему
    throw Exception('Не удалось найти подходящую систему тренировок');
  }

  /// Создание тренировок из системы
  Future<List<Workout>> _createWorkoutsFromSystem(
    TrainingSystemTemplate system,
    UserPreferences prefs,
  ) async {
    final workouts = <Workout>[];
    final daysPerWeek = prefs.daysPerWeek ?? system.recommendedDaysPerWeek;
    
    // Получаем все упражнения (с кэшированием)
    final allExercises = _getAllExercises();
    if (allExercises.isEmpty) {
      throw Exception('Список упражнений пуст');
    }
    
    // Адаптируем количество дней под предпочтения пользователя
    final adaptedStructure = _adaptWeeklyStructure(system.weeklyStructure, daysPerWeek);
    
    for (final entry in adaptedStructure.entries) {
      final dayNumber = entry.key;
      final dayTemplate = entry.value;
      
      if (dayTemplate.isRestDay) {
        // День отдыха
        workouts.add(Workout(
          id: 'rest_day_$dayNumber',
          name: 'День отдыха',
          dayOfWeek: dayNumber,
          exercises: [],
          duration: 0,
          completed: false,
          isRestDay: true,
        ));
      } else {
        // Тренировочный день
        final exercises = await _createExercisesForDay(
          dayTemplate,
          prefs,
          allExercises,
          system.system,
        );
        
        // Если упражнений нет, пропускаем этот день или делаем его днем отдыха
        if (exercises.isEmpty) {
          workouts.add(Workout(
            id: 'rest_day_$dayNumber',
            name: 'День отдыха',
            dayOfWeek: dayNumber,
            exercises: [],
            duration: 0,
            completed: false,
            isRestDay: true,
          ));
          continue;
        }
        
        // Рассчитываем длительность
        final duration = _calculateWorkoutDuration(exercises, prefs.sessionDuration);
        
        workouts.add(Workout(
          id: 'workout_${system.system.displayName}_$dayNumber',
          name: 'День $dayNumber: ${dayTemplate.focus}',
          dayOfWeek: dayNumber,
          exercises: exercises,
          duration: duration,
          completed: false,
          focus: dayTemplate.focus,
        ));
      }
    }
    
    return workouts;
  }

  /// Определение целевого количества упражнений на основе уровня подготовки
  int _getTargetExerciseCount(ExperienceLevel? level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return 4;
      case ExperienceLevel.intermediate:
        return 5;
      case ExperienceLevel.advanced:
        return 6;
      default:
        return 4; // По умолчанию для новичков
    }
  }

  /// Создание упражнений для дня
  Future<List<WorkoutExercise>> _createExercisesForDay(
    WorkoutDayTemplate dayTemplate,
    UserPreferences prefs,
    List<Exercise> allExercises,
    TrainingSystem system,
  ) async {
    final exercises = <WorkoutExercise>[];
    final targetCount = _getTargetExerciseCount(prefs.experienceLevel);
    
    for (final template in dayTemplate.exercises) {
      // 1. Проверяем безопасность упражнения
      if (!ExerciseSelectionRules.isExerciseSafeForUser(
        template.exerciseId,
        prefs,
        allExercises: allExercises,
      )) {
        continue; // Пропускаем небезопасные упражнения
      }
      
      // 2. Проверяем доступность оборудования
      final equipmentAvailable = _isExerciseEquipmentAvailable(
        template.exerciseId,
        prefs.availableEquipment,
        allExercises,
      );
      
      String exerciseIdToUse = template.exerciseId;
      
      if (!equipmentAvailable) {
        // Ищем альтернативу
        final alternatives = ExerciseSelectionRules.getEquipmentReplacements(
          template.exerciseId,
          prefs.availableEquipment,
          allExercises,
        );
        
        if (alternatives.isNotEmpty) {
          exerciseIdToUse = alternatives.first;
        } else {
          continue; // Пропускаем если нет альтернатив
        }
      }
      
      // 3. Проверяем совместимость с системой тренировок
      if (!ExerciseSelectionRules.isExerciseCompatibleWithSystem(
        exerciseIdToUse,
        system,
        dayTemplate.dayNumber,
        dayTemplate.focus,
      )) {
        continue; // Пропускаем несовместимые упражнения
      }
      
      // 4. Адаптируем параметры под пользователя
      final adaptedTemplate = ExerciseSelectionRules.adaptExerciseForUser(
        template,
        prefs.experienceLevel ?? ExperienceLevel.beginner,
        prefs.goal ?? UserGoal.generalFitness,
        prefs.bodyType,
      );
      
      // 5. Проверяем, что упражнение еще не добавлено (избегаем дубликатов)
      if (exercises.any((e) => e.exerciseId == exerciseIdToUse)) {
        continue; // Пропускаем дубликаты
      }
      
      // 6. Создаем упражнение
      exercises.add(WorkoutExercise(
        exerciseId: exerciseIdToUse,
        sets: adaptedTemplate.sets,
        reps: adaptedTemplate.reps,
        restTime: adaptedTemplate.restTime,
        notes: template.notes,
      ));
    }
    
    // Если все упражнения были пропущены, добавляем базовые упражнения
    if (exercises.isEmpty && dayTemplate.exercises.isNotEmpty) {
      // Пытаемся найти хотя бы одно доступное упражнение
      for (final template in dayTemplate.exercises) {
        final exercise = allExercises.firstWhere(
          (e) => e.id == template.exerciseId,
          orElse: () => Exercise.empty(),
        );
        
        if (exercise.id.isNotEmpty) {
          // Проверяем базовую доступность (bodyweight или минимальное оборудование)
          final isBasicAvailable = exercise.isBodyweight || 
              exercise.requiredEquipment.isEmpty ||
              exercise.requiredEquipment.any((eq) => 
                prefs.availableEquipment.any((avail) => avail.displayName == eq));
          
          if (isBasicAvailable) {
            final adaptedTemplate = ExerciseSelectionRules.adaptExerciseForUser(
              template,
              prefs.experienceLevel ?? ExperienceLevel.beginner,
              prefs.goal ?? UserGoal.generalFitness,
              prefs.bodyType,
            );
            
            exercises.add(WorkoutExercise(
              exerciseId: template.exerciseId,
              sets: adaptedTemplate.sets,
              reps: adaptedTemplate.reps,
              restTime: adaptedTemplate.restTime,
              notes: template.notes,
            ));
            break; // Добавляем хотя бы одно упражнение
          }
        }
      }
    }
    
    // 5. Адаптируем количество упражнений под уровень подготовки
    if (exercises.isEmpty) {
      // Если упражнений нет, возвращаем пустой список
      return exercises;
    }
    
    // Если упражнений меньше целевого - добавляем дополнительные
    if (exercises.length < targetCount) {
      final additionalExercises = await _getAdditionalExercises(
        dayTemplate,
        prefs,
        allExercises,
        system,
        exercises.map((e) => e.exerciseId).toList(),
        targetCount - exercises.length,
      );
      exercises.addAll(additionalExercises);
    }
    
    // Балансируем тренировку с учетом целевого количества (только основные упражнения)
    final mainExercises = _balanceWorkoutExercises(exercises, dayTemplate.focus, system, targetCount);
    
    // Добавляем разминку и заминку, затем сортируем в правильном порядке
    return _addWarmupAndCooldown(mainExercises, prefs, allExercises);
  }
  
  /// Получить дополнительные упражнения для достижения целевого количества
  Future<List<WorkoutExercise>> _getAdditionalExercises(
    WorkoutDayTemplate dayTemplate,
    UserPreferences prefs,
    List<Exercise> allExercises,
    TrainingSystem system,
    List<String> existingExerciseIds,
    int neededCount,
  ) async {
    final additionalExercises = <WorkoutExercise>[];
    
    // Получаем доступные упражнения для фокуса дня
    final focusMuscleGroups = _extractMuscleGroupsFromFocus(dayTemplate.focus);
    
    // Для дополнительных упражнений используем более мягкую фильтрацию
    // Основные требования: безопасность и доступность оборудования
    final availableExercises = allExercises.where((exercise) {
      // Не включаем уже добавленные упражнения
      if (existingExerciseIds.contains(exercise.id)) return false;
      
      // Обязательные проверки: безопасность и оборудование
      if (!ExerciseSelectionRules.isExerciseSafeForUser(exercise.id, prefs, allExercises: allExercises)) {
        return false;
      }
      
      final equipmentAvailable = _isExerciseEquipmentAvailable(
        exercise.id,
        prefs.availableEquipment,
        allExercises,
      );
      if (!equipmentAvailable) return false;
      
      // Исключаем разминку и заминку из основных упражнений
      if (exercise.isWarmup || exercise.isCooldown) return false;
      
      return true; // Для дополнительных упражнений принимаем все безопасные и доступные
    }).toList();
    
    // Фильтруем упражнения по соответствию фокусу дня (строгая фильтрация)
    final focusFiltered = availableExercises.where((exercise) {
      // Если фокус не определен, принимаем все упражнения
      if (focusMuscleGroups.isEmpty) return true;
      
      // Проверяем соответствие основным группам мышц
      final exerciseMuscles = [
        ...exercise.primaryMuscleGroups,
        ...exercise.secondaryMuscleGroups,
      ];
      
      // Проверяем совпадение с фокусом дня
      final matchesFocus = focusMuscleGroups.any((focusMuscle) {
        return exerciseMuscles.any((exerciseMuscle) {
          final focusLower = focusMuscle.toLowerCase();
          final exerciseLower = exerciseMuscle.toLowerCase();
          return exerciseLower.contains(focusLower) || 
                 focusLower.contains(exerciseLower);
        });
      });
      
      // Также проверяем по категориям упражнений
      final matchesByCategory = _matchesFocusByCategory(exercise, dayTemplate.focus);
      
      // Принимаем упражнение если оно соответствует фокусу или это fullBody упражнение
      return matchesFocus || matchesByCategory || exercise.categories.contains(ExerciseCategory.fullBody);
    }).toList();
    
    // Приоритизируем упражнения по соответствию фокусу дня
    focusFiltered.sort((a, b) {
      final aMatchesFocus = focusMuscleGroups.isEmpty || 
          a.primaryMuscleGroups.any((m) => focusMuscleGroups.any((fm) => 
            m.toLowerCase().contains(fm.toLowerCase()) || 
            fm.toLowerCase().contains(m.toLowerCase()))) ||
          a.categories.contains(ExerciseCategory.fullBody);
      
      final bMatchesFocus = focusMuscleGroups.isEmpty || 
          b.primaryMuscleGroups.any((m) => focusMuscleGroups.any((fm) => 
            m.toLowerCase().contains(fm.toLowerCase()) || 
            fm.toLowerCase().contains(m.toLowerCase()))) ||
          b.categories.contains(ExerciseCategory.fullBody);
      
      if (aMatchesFocus && !bMatchesFocus) return -1;
      if (!aMatchesFocus && bMatchesFocus) return 1;
      return 0;
    });
    
    // Фильтруем по уровню подготовки
    final levelFiltered = focusFiltered.where((exercise) {
      switch (prefs.experienceLevel) {
        case ExperienceLevel.beginner:
          return exercise.difficulty == ExerciseDifficulty.beginner ||
                 exercise.difficulty == ExerciseDifficulty.intermediate;
        case ExperienceLevel.intermediate:
          // Средний уровень может выполнять упражнения для начинающих и среднего уровня
          return exercise.difficulty == ExerciseDifficulty.beginner ||
                 exercise.difficulty == ExerciseDifficulty.intermediate;
        case ExperienceLevel.advanced:
          return true; // Опытные могут выполнять любые упражнения
        default:
          return exercise.difficulty == ExerciseDifficulty.beginner;
      }
    }).toList();
    
    // Выбираем нужное количество упражнений
    // Приоритизируем упражнения, которые соответствуют уровню, но если их недостаточно - берем любые доступные
    List<Exercise> exercisesToUse = levelFiltered;
    if (levelFiltered.length < neededCount) {
      // Если после фильтрации по уровню недостаточно упражнений, используем все доступные
      // Это гарантирует, что мы добавим нужное количество упражнений
      exercisesToUse = availableExercises;
    }
    
    exercisesToUse.shuffle(); // Перемешиваем для разнообразия
    final selected = exercisesToUse.take(neededCount);
    
    for (final exercise in selected) {
      // Адаптируем параметры под пользователя
      final defaultTemplate = ExerciseTemplate(
        exerciseId: exercise.id,
        sets: exercise.defaultSets,
        reps: exercise.defaultReps,
        restTime: exercise.restTimeSeconds,
      );
      
      final adaptedTemplate = ExerciseSelectionRules.adaptExerciseForUser(
        defaultTemplate,
        prefs.experienceLevel ?? ExperienceLevel.beginner,
        prefs.goal ?? UserGoal.generalFitness,
        prefs.bodyType,
      );
      
      // Проверяем, что упражнение еще не добавлено (избегаем дубликатов)
      if (!additionalExercises.any((e) => e.exerciseId == exercise.id)) {
        additionalExercises.add(WorkoutExercise(
          exerciseId: exercise.id,
          sets: adaptedTemplate.sets,
          reps: adaptedTemplate.reps,
          restTime: adaptedTemplate.restTime,
        ));
      }
    }
    
    return additionalExercises;
  }
  
  /// Извлечь группы мышц из фокуса дня
  List<String> _extractMuscleGroupsFromFocus(String focus) {
    final muscleGroups = <String>[];
    final focusLower = focus.toLowerCase();
    
    // Основные группы мышц
    if (focusLower.contains('грудь') || focusLower.contains('chest')) {
      muscleGroups.add('Грудь');
      muscleGroups.add('Грудные');
    }
    if (focusLower.contains('спина') || focusLower.contains('back')) {
      muscleGroups.add('Спина');
      muscleGroups.add('Широчайшие');
    }
    if (focusLower.contains('ноги') || focusLower.contains('legs')) {
      muscleGroups.add('Ноги');
      muscleGroups.add('Квадрицепсы');
      muscleGroups.add('Бицепсы бедра');
      muscleGroups.add('Ягодицы');
    }
    if (focusLower.contains('плечи') || focusLower.contains('shoulders')) {
      muscleGroups.add('Плечи');
      muscleGroups.add('Дельты');
    }
    if (focusLower.contains('бицепс') || focusLower.contains('biceps')) {
      muscleGroups.add('Бицепсы');
      muscleGroups.add('Бицепс');
    }
    if (focusLower.contains('трицепс') || focusLower.contains('triceps')) {
      muscleGroups.add('Трицепсы');
      muscleGroups.add('Трицепс');
    }
    if (focusLower.contains('пресс') || focusLower.contains('abs') || focusLower.contains('core')) {
      muscleGroups.add('Пресс');
    }
    
    return muscleGroups;
  }
  
  /// Проверить соответствие упражнения фокусу дня по категориям
  bool _matchesFocusByCategory(Exercise exercise, String focus) {
    final focusLower = focus.toLowerCase();
    
    // Проверяем по категориям упражнения
    if (focusLower.contains('ноги') || focusLower.contains('legs')) {
      return exercise.categories.contains(ExerciseCategory.legs) ||
             exercise.primaryMuscleGroups.any((m) => 
               m.toLowerCase().contains('ноги') || 
               m.toLowerCase().contains('бедр') ||
               m.toLowerCase().contains('квадрицепс') ||
               m.toLowerCase().contains('ягодиц'));
    }
    
    if (focusLower.contains('грудь') || focusLower.contains('chest')) {
      return exercise.categories.contains(ExerciseCategory.chest) ||
             exercise.primaryMuscleGroups.any((m) => 
               m.toLowerCase().contains('груд'));
    }
    
    if (focusLower.contains('спина') || focusLower.contains('back')) {
      return exercise.categories.contains(ExerciseCategory.back) ||
             exercise.primaryMuscleGroups.any((m) => 
               m.toLowerCase().contains('спин') ||
               m.toLowerCase().contains('широчайш'));
    }
    
    if (focusLower.contains('плечи') || focusLower.contains('shoulders')) {
      return exercise.categories.contains(ExerciseCategory.shoulders) ||
             exercise.primaryMuscleGroups.any((m) => 
               m.toLowerCase().contains('плеч') ||
               m.toLowerCase().contains('дельт'));
    }
    
    if (focusLower.contains('руки') || focusLower.contains('arms') || 
        focusLower.contains('бицепс') || focusLower.contains('трицепс')) {
      return exercise.categories.contains(ExerciseCategory.arms) ||
             exercise.primaryMuscleGroups.any((m) => 
               m.toLowerCase().contains('бицепс') ||
               m.toLowerCase().contains('трицепс') ||
               m.toLowerCase().contains('предплеч'));
    }
    
    if (focusLower.contains('пресс') || focusLower.contains('abs')) {
      return exercise.categories.contains(ExerciseCategory.abs);
    }
    
    // Для Push/Pull/Legs систем
    if (focusLower.contains('push')) {
      return exercise.categories.contains(ExerciseCategory.chest) ||
             exercise.categories.contains(ExerciseCategory.shoulders) ||
             (exercise.categories.contains(ExerciseCategory.arms) &&
              exercise.primaryMuscleGroups.any((m) => 
                m.toLowerCase().contains('трицепс')));
    }
    
    if (focusLower.contains('pull')) {
      return exercise.categories.contains(ExerciseCategory.back) ||
             (exercise.categories.contains(ExerciseCategory.arms) &&
              exercise.primaryMuscleGroups.any((m) => 
                m.toLowerCase().contains('бицепс')));
    }
    
    return false;
  }

  /// Адаптация недельной структуры под количество дней
  Map<int, WorkoutDayTemplate> _adaptWeeklyStructure(
    Map<int, WorkoutDayTemplate> originalStructure,
    int targetDays,
  ) {
    if (targetDays >= originalStructure.length) {
      return originalStructure;
    }
    
    final adaptedStructure = <int, WorkoutDayTemplate>{};
    
    // Подсчитываем тренировочные дни
    final workoutDays = originalStructure.values
        .where((day) => !day.isRestDay)
        .toList();
    
    // Оставляем только нужное количество тренировочных дней
    final selectedWorkoutDays = workoutDays.take(targetDays).toList();
    
    // Создаем новую структуру
    for (int i = 0; i < targetDays; i++) {
      if (i < selectedWorkoutDays.length) {
        adaptedStructure[i + 1] = selectedWorkoutDays[i].copyWith(dayNumber: i + 1);
      } else {
        // Заполняем оставшиеся дни отдыхом
        adaptedStructure[i + 1] = WorkoutDayTemplate(
          dayNumber: i + 1,
          focus: 'Rest Day',
          exercises: [],
          isRestDay: true,
        );
      }
    }
    
    return adaptedStructure;
  }

  /// Получить все упражнения (с кэшированием)
  List<Exercise> _getAllExercises() {
    if (_allExercisesCache == null) {
      try {
        final exercises = _workoutRepository.allExercises;
        if (exercises.isEmpty) {
          throw Exception('Список упражнений пуст');
        }
        _allExercisesCache = exercises;
      } catch (e) {
        throw Exception('Не удалось загрузить упражнения из репозитория: $e');
      }
    }
    return _allExercisesCache ?? [];
  }

  /// Получить упражнения по доступному оборудованию (с кэшированием)
  List<Exercise> _getExercisesByEquipment(List<Equipment> availableEquipment) {
    final equipmentKey = availableEquipment.map((e) => e.displayName).join(',');
    
    if (_equipmentExerciseCache.containsKey(equipmentKey)) {
      return _equipmentExerciseCache[equipmentKey]!;
    }
    
    final allExercises = _getAllExercises();
    final availableEquipmentNames = availableEquipment.map((e) => e.displayName).toList();
    
    final filteredExercises = allExercises.where((exercise) {
      if (exercise.isBodyweight && exercise.requiredEquipment.isEmpty) {
        return true;
      }
      return exercise.requiredEquipment.every(
        (requiredEq) => availableEquipmentNames.contains(requiredEq),
      );
    }).toList();
    
    // Сохраняем в кэш (ограничиваем размер до 20)
    if (_equipmentExerciseCache.length >= 20) {
      final firstKey = _equipmentExerciseCache.keys.first;
      _equipmentExerciseCache.remove(firstKey);
    }
    _equipmentExerciseCache[equipmentKey] = filteredExercises;
    
    return filteredExercises;
  }

  /// Проверка доступности оборудования для упражнения
  bool _isExerciseEquipmentAvailable(
    String exerciseId,
    List<Equipment> availableEquipment,
    List<Exercise> allExercises,
  ) {
    final exercise = allExercises.firstWhere(
      (e) => e.id == exerciseId,
      orElse: () => Exercise.empty(),
    );
    
    if (exercise.id.isEmpty) return false;
    
    // Если упражнение с весом тела и нет оборудования - доступно
    if (exercise.isBodyweight && exercise.requiredEquipment.isEmpty) {
      return true;
    }
    
    // Проверяем оборудование
    final availableEquipmentNames = availableEquipment.map((e) => e.displayName).toList();
    
    return exercise.requiredEquipment.every(
      (requiredEq) => availableEquipmentNames.contains(requiredEq),
    );
  }
  
  /// Очистить кэш
  void clearCache() {
    _planCache.clear();
    _equipmentExerciseCache.clear();
    _allExercisesCache = null;
  }

  /// Балансировка упражнений в тренировке с учетом целевого количества
  /// Исключает разминку и заминку из балансировки, но сохраняет их для последующей сортировки
  List<WorkoutExercise> _balanceWorkoutExercises(
    List<WorkoutExercise> exercises,
    String focus,
    TrainingSystem system,
    int targetCount,
  ) {
    // Разделяем на основные упражнения и разминку/заминку
    final mainExercises = <WorkoutExercise>[];
    final warmupCooldown = <WorkoutExercise>[];
    
    // Получаем все упражнения для проверки типа
    final allExercises = _workoutRepository.allExercises;
    
    for (final exercise in exercises) {
      final exerciseDetails = allExercises.firstWhere(
        (e) => e.id == exercise.exerciseId,
        orElse: () => Exercise.empty(),
      );
      
      // Проверяем по флагу, категориям и префиксу ID для надежности
      final isWarmup = exerciseDetails.id.isNotEmpty && (
        exerciseDetails.isWarmup || 
        exerciseDetails.categories.contains(ExerciseCategory.warmup)
      ) || exercise.exerciseId.startsWith('warmup_');
      
      final isCooldown = exerciseDetails.id.isNotEmpty && (
        exerciseDetails.isCooldown || 
        exerciseDetails.categories.contains(ExerciseCategory.cooldown)
      ) || exercise.exerciseId.startsWith('cooldown_');
      
      if (exerciseDetails.id.isEmpty || isWarmup || isCooldown) {
        warmupCooldown.add(exercise);
      } else {
        mainExercises.add(exercise);
      }
    }
    
    // Балансируем только основные упражнения
    List<WorkoutExercise> balancedMain = mainExercises;
    if (mainExercises.length > targetCount) {
      // Если основных упражнений больше целевого - выбираем разнообразные упражнения
      final balanced = <WorkoutExercise>[];
      final usedTypes = <String>{};
      
      // Сначала добавляем по одному упражнению из каждой группы для разнообразия
      for (final exercise in mainExercises) {
        if (balanced.length >= targetCount) break;
        
        final type = _getExerciseType(exercise.exerciseId);
        if (!usedTypes.contains(type)) {
          balanced.add(exercise);
          usedTypes.add(type);
        }
      }
      
      // Если еще не достигли целевого количества, добавляем оставшиеся упражнения
      if (balanced.length < targetCount) {
        for (final exercise in mainExercises) {
          if (balanced.length >= targetCount) break;
          if (!balanced.any((e) => e.exerciseId == exercise.exerciseId)) {
            balanced.add(exercise);
          }
        }
      }
      
      // Если все еще не достигли целевого количества, добавляем любые оставшиеся
      if (balanced.length < targetCount) {
        for (final exercise in mainExercises) {
          if (balanced.length >= targetCount) break;
          balanced.add(exercise);
        }
      }
      
      balancedMain = balanced.take(targetCount).toList();
    }
    
    // Возвращаем все упражнения вместе (разминка/заминка будут отсортированы позже)
    // ВАЖНО: возвращаем все упражнения, чтобы они не потерялись
    final result = <WorkoutExercise>[];
    result.addAll(warmupCooldown); // Добавляем разминку и заминку
    result.addAll(balancedMain);   // Добавляем основные упражнения
    return result;
  }

  /// Определение типа упражнения по ID
  String _getExerciseType(String exerciseId) {
    if (exerciseId.startsWith('chest_')) return 'chest';
    if (exerciseId.startsWith('back_')) return 'back';
    if (exerciseId.startsWith('legs_')) return 'legs';
    if (exerciseId.startsWith('shoulders_')) return 'shoulders';
    if (exerciseId.startsWith('arms_')) return 'arms';
    if (exerciseId.startsWith('abs_')) return 'abs';
    if (exerciseId.startsWith('cardio_')) return 'cardio';
    return 'other';
  }

  /// Добавление разминки и заминки с правильной сортировкой
  List<WorkoutExercise> _addWarmupAndCooldown(
    List<WorkoutExercise> mainExercises,
    UserPreferences prefs,
    List<Exercise> allExercises,
  ) {
    final result = <WorkoutExercise>[];
    
    // Разделяем упражнения на категории
    final warmupExercises = <WorkoutExercise>[];
    final mainWorkoutExercises = <WorkoutExercise>[];
    final cooldownExercises = <WorkoutExercise>[];
    
    // Сортируем существующие упражнения по категориям
    for (final exercise in mainExercises) {
      final exerciseDetails = allExercises.firstWhere(
        (e) => e.id == exercise.exerciseId,
        orElse: () => Exercise.empty(),
      );
      
      if (exerciseDetails.id.isEmpty) {
        // Если упражнение не найдено, проверяем по ID
        if (exercise.exerciseId.startsWith('warmup_')) {
          warmupExercises.add(exercise);
        } else if (exercise.exerciseId.startsWith('cooldown_')) {
          cooldownExercises.add(exercise);
        } else {
          mainWorkoutExercises.add(exercise);
        }
        continue;
      }
      
      // Проверяем по флагу и категориям для надежности
      final isWarmup = exerciseDetails.isWarmup || 
          exerciseDetails.categories.contains(ExerciseCategory.warmup) ||
          exercise.exerciseId.startsWith('warmup_');
      final isCooldown = exerciseDetails.isCooldown || 
          exerciseDetails.categories.contains(ExerciseCategory.cooldown) ||
          exercise.exerciseId.startsWith('cooldown_');
      
      if (isWarmup) {
        warmupExercises.add(exercise);
      } else if (isCooldown) {
        cooldownExercises.add(exercise);
      } else {
        mainWorkoutExercises.add(exercise);
      }
    }
    
    // Добавляем разминку, если её нет или недостаточно
    if (warmupExercises.isEmpty || warmupExercises.length < 2) {
      final warmupCount = warmupExercises.isEmpty ? 3 : (3 - warmupExercises.length);
      final availableWarmup = _workoutRepository.getDefaultWarmup(count: warmupCount);
      
      for (final warmupExercise in availableWarmup) {
        // Проверяем безопасность и доступность оборудования
        if (ExerciseSelectionRules.isExerciseSafeForUser(warmupExercise.id, prefs, allExercises: allExercises) &&
            _isExerciseEquipmentAvailable(
              warmupExercise.id,
              prefs.availableEquipment,
              allExercises,
            )) {
          // Проверяем, что это упражнение еще не добавлено
          if (!warmupExercises.any((e) => e.exerciseId == warmupExercise.id)) {
            warmupExercises.add(WorkoutExercise(
              exerciseId: warmupExercise.id,
              sets: warmupExercise.defaultSets,
              reps: warmupExercise.defaultReps,
              restTime: warmupExercise.restTimeSeconds,
            ));
          }
        }
      }
    }
    
    // Добавляем заминку, если её нет или недостаточно
    if (cooldownExercises.isEmpty || cooldownExercises.length < 2) {
      final cooldownCount = cooldownExercises.isEmpty ? 3 : (3 - cooldownExercises.length);
      final availableCooldown = _workoutRepository.getDefaultCooldown(count: cooldownCount);
      
      for (final cooldownExercise in availableCooldown) {
        // Проверяем безопасность и доступность оборудования
        if (ExerciseSelectionRules.isExerciseSafeForUser(cooldownExercise.id, prefs, allExercises: allExercises) &&
            _isExerciseEquipmentAvailable(
              cooldownExercise.id,
              prefs.availableEquipment,
              allExercises,
            )) {
          // Проверяем, что это упражнение еще не добавлено
          if (!cooldownExercises.any((e) => e.exerciseId == cooldownExercise.id)) {
            cooldownExercises.add(WorkoutExercise(
              exerciseId: cooldownExercise.id,
              sets: cooldownExercise.defaultSets,
              reps: cooldownExercise.defaultReps,
              restTime: cooldownExercise.restTimeSeconds,
            ));
          }
        }
      }
    }
    
    // Собираем результат в правильном порядке: разминка -> основные -> заминка
    result.addAll(warmupExercises);
    result.addAll(mainWorkoutExercises);
    result.addAll(cooldownExercises);
    
    return result;
  }

  /// Расчет длительности тренировки
  int _calculateWorkoutDuration(
    List<WorkoutExercise> exercises,
    int? targetDuration,
  ) {
    if (exercises.isEmpty) return 0;
    
    // Базовый расчет: 3 минуты на подход (выполнение + отдых)
    int totalSets = exercises.fold(0, (sum, ex) => sum + ex.sets);
    int calculatedDuration = totalSets * 3;
    
    // Добавляем время на разминку и заминку
    calculatedDuration += 15;
    
    // Если есть целевая длительность, корректируем
    if (targetDuration != null) {
      if (calculatedDuration > targetDuration * 1.2) {
        // Уменьшаем количество подходов
        return targetDuration;
      } else if (calculatedDuration < targetDuration * 0.8) {
        // Можно добавить упражнения, но в этом методе просто возвращаем целевую
        return targetDuration;
      }
    }
    
    return calculatedDuration.clamp(30, 120);
  }

  /// Генерация названия плана
  String _generatePlanName(TrainingSystem system, UserPreferences prefs) {
    final goalName = prefs.goal?.displayName ?? 'Тренировки';
    final systemName = system.displayName;
    
    return '$systemName: План для $goalName';
  }

  /// Генерация описания плана
  String _generatePlanDescription(
    TrainingSystemTemplate system,
    UserPreferences prefs,
  ) {
    final parts = <String>[];
    
    parts.add(system.description);
    
    if (prefs.daysPerWeek != null) {
      parts.add('${prefs.daysPerWeek} тренировок в неделю');
    }
    
    if (prefs.sessionDuration != null) {
      parts.add('${prefs.sessionDuration} минут на тренировку');
    }
    
    if (prefs.experienceLevel != null) {
      parts.add('Уровень: ${prefs.experienceLevel?.displayName ?? 'Не указано'}');
    }
    
    return parts.join(' • ');
  }

  /// Генерация детального объяснения выбора плана
  Map<String, dynamic> _generatePlanExplanation(
    TrainingSystemTemplate system,
    UserPreferences prefs,
  ) {
    final explanation = <String, dynamic>{};
    
    // Объяснение выбора системы тренировок
    explanation['systemReason'] = _getSystemSelectionReason(system.system, prefs);
    
    // Объяснение параметров тренировок
    explanation['parametersReason'] = _getParametersReason(prefs);
    
    // Объяснение подбора упражнений
    explanation['exerciseSelectionReason'] = _getExerciseSelectionReason(prefs);
    
    return explanation;
  }

  /// Причина выбора системы тренировок
  String _getSystemSelectionReason(TrainingSystem system, UserPreferences prefs) {
    final reasons = <String>[];
    
    // Связь с уровнем подготовки
    if (prefs.experienceLevel != null) {
      switch (prefs.experienceLevel!) {
        case ExperienceLevel.beginner:
          if (system == TrainingSystem.fullBody || system == TrainingSystem.upperLower) {
            reasons.add('Выбрана система "${system.displayName}", так как вы новичок. '
                'Эта система идеально подходит для начинающих, так как позволяет '
                'развить общую силу и координацию без перегрузки организма.');
          } else if (system == TrainingSystem.circuit) {
            reasons.add('Выбрана система "${system.displayName}" для новичков, '
                'так как она развивает выносливость и координацию, что важно на начальном этапе.');
          }
          break;
        case ExperienceLevel.intermediate:
          if (system == TrainingSystem.split || system == TrainingSystem.ppl) {
            reasons.add('Выбрана система "${system.displayName}" для среднего уровня подготовки. '
                'Эта система позволяет более целенаправленно развивать отдельные группы мышц, '
                'что оптимально для вашего уровня опыта.');
          }
          break;
        case ExperienceLevel.advanced:
          if (system == TrainingSystem.ppl || system == TrainingSystem.split) {
            reasons.add('Выбрана система "${system.displayName}" для опытных спортсменов. '
                'Эта система обеспечивает максимальную нагрузку на каждую группу мышц '
                'и позволяет достичь высоких результатов.');
          }
          break;
      }
    }
    
    // Связь с целью тренировок
    if (prefs.goal != null) {
      switch (prefs.goal!) {
        case UserGoal.weightLoss:
          if (system == TrainingSystem.circuit) {
            reasons.add('Система "${system.displayName}" оптимальна для похудения, '
                'так как обеспечивает высокую интенсивность и расход калорий.');
          } else if (system == TrainingSystem.fullBody) {
            reasons.add('Система "${system.displayName}" способствует похудению за счет '
                'работы всех групп мышц и высокого расхода энергии.');
          }
          break;
        case UserGoal.muscleGain:
          if (system == TrainingSystem.ppl || system == TrainingSystem.split) {
            reasons.add('Система "${system.displayName}" идеальна для набора мышечной массы, '
                'так как позволяет максимально нагрузить каждую группу мышц.');
          }
          break;
        case UserGoal.strength:
          if (system == TrainingSystem.upperLower || system == TrainingSystem.split) {
            reasons.add('Система "${system.displayName}" оптимальна для развития силы, '
                'так как позволяет работать с большими весами и достаточным отдыхом.');
          }
          break;
        case UserGoal.endurance:
          if (system == TrainingSystem.circuit || system == TrainingSystem.cardio) {
            reasons.add('Система "${system.displayName}" развивает выносливость за счет '
                'высокой интенсивности и большого объема работы.');
          }
          break;
        case UserGoal.generalFitness:
          reasons.add('Система "${system.displayName}" обеспечивает сбалансированное развитие '
              'всех физических качеств.');
          break;
      }
    }
    
    // Связь с количеством дней
    if (prefs.daysPerWeek != null) {
      final days = prefs.daysPerWeek!;
      if (days <= 3) {
        if (system == TrainingSystem.fullBody || system == TrainingSystem.upperLower) {
          reasons.add('Система "${system.displayName}" оптимальна для ${days} тренировок в неделю, '
              'так как позволяет проработать все тело за ограниченное количество дней.');
        }
      } else if (days >= 5) {
        if (system == TrainingSystem.ppl || system == TrainingSystem.split) {
          reasons.add('Система "${system.displayName}" идеально подходит для ${days} тренировок в неделю, '
              'так как позволяет распределить нагрузку на разные группы мышц.');
        }
      }
    }
    
    // Связь с местом тренировок
    if (prefs.trainingLocation != null) {
      switch (prefs.trainingLocation!) {
        case TrainingLocation.home:
          if (system == TrainingSystem.fullBody || system == TrainingSystem.circuit) {
            reasons.add('Система "${system.displayName}" оптимальна для домашних тренировок, '
                'так как не требует сложного оборудования.');
          }
          break;
        case TrainingLocation.gym:
          if (system == TrainingSystem.split || system == TrainingSystem.ppl) {
            reasons.add('Система "${system.displayName}" идеальна для тренажерного зала, '
                'где есть доступ к разнообразному оборудованию.');
          }
          break;
        case TrainingLocation.street:
        case TrainingLocation.bodyweight:
          if (system == TrainingSystem.circuit || system == TrainingSystem.fullBody) {
            reasons.add('Система "${system.displayName}" подходит для тренировок с весом тела '
                'и минимальным оборудованием.');
          }
          break;
      }
    }
    
    if (reasons.isEmpty) {
      return 'Система "${system.displayName}" выбрана на основе ваших предпочтений и параметров.';
    }
    
    return reasons.join(' ');
  }

  /// Причина выбора параметров тренировок
  String _getParametersReason(UserPreferences prefs) {
    final reasons = <String>[];
    
    if (prefs.experienceLevel != null && prefs.goal != null) {
      switch (prefs.experienceLevel!) {
        case ExperienceLevel.beginner:
          reasons.add('Для новичков выбраны умеренные параметры (3-4 подхода, 10-12 повторений), '
              'чтобы обеспечить безопасность и правильную технику выполнения.');
          break;
        case ExperienceLevel.intermediate:
          reasons.add('Для среднего уровня выбраны параметры, позволяющие прогрессировать '
              'в силе и выносливости.');
          break;
        case ExperienceLevel.advanced:
          reasons.add('Для опытных спортсменов выбраны параметры, обеспечивающие максимальную '
              'нагрузку и прогрессию.');
          break;
      }
      
      switch (prefs.goal!) {
        case UserGoal.weightLoss:
          reasons.add('Для похудения выбраны параметры с акцентом на количество повторений '
              'и умеренным временем отдыха для поддержания высокой интенсивности.');
          break;
        case UserGoal.muscleGain:
          reasons.add('Для набора массы выбраны параметры с акцентом на объем тренировки '
              'и достаточным временем отдыха для восстановления.');
          break;
        case UserGoal.strength:
          reasons.add('Для развития силы выбраны параметры с меньшим количеством повторений '
              'и увеличенным временем отдыха между подходами.');
          break;
        case UserGoal.endurance:
          reasons.add('Для развития выносливости выбраны параметры с большим количеством повторений '
              'и коротким временем отдыха между подходами.');
          break;
        case UserGoal.generalFitness:
          reasons.add('Для общей физической формы выбраны сбалансированные параметры, '
              'развивающие силу, выносливость и координацию.');
          break;
      }
    }
    
    if (reasons.isEmpty) {
      return 'Параметры тренировок подобраны на основе вашего уровня подготовки и целей.';
    }
    
    return reasons.join(' ');
  }

  /// Причина подбора упражнений
  String _getExerciseSelectionReason(UserPreferences prefs) {
    final reasons = <String>[];
    
    if (prefs.healthRestrictions.isNotEmpty && 
        !prefs.healthRestrictions.contains(HealthRestriction.none)) {
      final restrictions = prefs.healthRestrictions
          .where((r) => r != HealthRestriction.none)
          .map((r) => r.displayName)
          .join(', ');
      reasons.add('Все упражнения подобраны с учетом ваших ограничений по здоровью: $restrictions. '
          'Исключены упражнения, которые могут усугубить эти проблемы.');
    }
    
    if (prefs.trainingLocation != null) {
      reasons.add('Упражнения подобраны под ваше место тренировок: '
          '${prefs.trainingLocation!.displayName}. Все упражнения можно выполнить '
          'с доступным вам оборудованием.');
    }
    
    if (prefs.favoriteMuscleGroups.isNotEmpty) {
      reasons.add('В плане сделан акцент на ваши любимые группы мышц: '
          '${prefs.favoriteMuscleGroups.join(', ')}.');
    }
    
    if (prefs.dislikedExercises.isNotEmpty) {
      reasons.add('Исключены нелюбимые упражнения: ${prefs.dislikedExercises.join(', ')}.');
    }
    
    if (reasons.isEmpty) {
      return 'Упражнения подобраны на основе ваших предпочтений, доступного оборудования '
          'и ограничений по здоровью.';
    }
    
    return reasons.join(' ');
  }

  /// Fallback план если генерация не удалась
  WorkoutPlan _generateFallbackPlan(UserPreferences prefs) {
    // Простой план для новичков
    final exercises = [
      WorkoutExercise(exerciseId: 'chest_01', sets: 3, reps: 10),
      WorkoutExercise(exerciseId: 'legs_01', sets: 3, reps: 12),
      WorkoutExercise(exerciseId: 'back_03', sets: 3, reps: 8),
      WorkoutExercise(exerciseId: 'abs_02', sets: 3, reps: 30),
    ];
    
    final workouts = [
      Workout(
        id: 'fallback_1',
        name: 'Базовая тренировка',
        dayOfWeek: 1,
        exercises: exercises,
        duration: 45,
        completed: false,
      ),
    ];
    
    return WorkoutPlan(
      id: 'fallback_plan',
      userId: 'user',
      name: 'Базовый план тренировок',
      description: 'План на основе ваших предпочтений',
      workouts: workouts,
      createdAt: DateTime.now(),
      userPreferences: prefs,
    );
  }

  /// Получить рекомендации по прогрессии
  Map<String, String> getProgressionRecommendations(
    TrainingSystem system,
    UserPreferences prefs,
  ) {
    final recommendations = <String, String>{};
    
    switch (system) {
      case TrainingSystem.fullBody:
        recommendations['weight'] = 'Увеличивайте вес на 2.5-5% каждую неделю';
        recommendations['reps'] = 'Стремитесь к 12 повторениям, затем увеличивайте вес';
        recommendations['frequency'] = '3 раза в неделю для оптимального прогресса';
        break;
        
      case TrainingSystem.split:
        recommendations['weight'] = 'Фокусируйтесь на технике, вес раз в 2 недели';
        recommendations['volume'] = 'Добавляйте 1 подход каждую неделю';
        recommendations['rest'] = '72 часа отдыха для каждой группы мышц';
        break;
        
      case TrainingSystem.ppl:
        recommendations['weight'] = 'Прогрессируйте в основных упражнениях каждую тренировку';
        recommendations['frequency'] = 'Отдых 48 часов между тренировками одной группы';
        recommendations['deload'] = 'Каждую 4 неделю уменьшайте объем на 50%';
        break;
        
      case TrainingSystem.upperLower:
        recommendations['weight'] = 'Чередуйте тяжелые и легкие дни';
        recommendations['progression'] = 'Увеличивайте вес на 2.5% в неделю';
        recommendations['variation'] = 'Меняйте упражнения каждые 4-6 недель';
        break;
        
      case TrainingSystem.circuit:
        recommendations['intensity'] = 'Уменьшайте время отдыха между упражнениями';
        recommendations['volume'] = 'Увеличивайте количество кругов';
        recommendations['variation'] = 'Добавляйте новые упражнения каждую неделю';
        break;
        
      case TrainingSystem.cardio:
        recommendations['duration'] = 'Увеличивайте длительность на 10% в неделю';
        recommendations['intensity'] = 'Добавляйте интервалы высокой интенсивности';
        recommendations['frequency'] = '3-4 раза в неделю для оптимальных результатов';
        break;
    }
    
    // Добавляем рекомендации по цели
    if (prefs.goal != null) {
      switch (prefs.goal!) {
        case UserGoal.weightLoss:
          recommendations['nutrition'] = 'Дефицит 300-500 калорий в день';
          recommendations['cardio'] = 'Добавьте 2-3 кардио сессии в неделю';
          break;
        case UserGoal.muscleGain:
          recommendations['nutrition'] = 'Профицит 300-500 калорий, 2г белка на кг веса';
          recommendations['rest'] = 'Спите 7-9 часов, отдых между тренировками';
          break;
        case UserGoal.strength:
          recommendations['intensity'] = 'Фокусируйтесь на 3-6 повторениях с большим весом';
          recommendations['rest'] = '3-5 минут отдыха между подходами';
          break;
        case UserGoal.endurance:
          recommendations['volume'] = 'Увеличивайте количество повторений и подходов';
          recommendations['rest'] = 'Короткий отдых (30-60 секунд)';
          break;
        case UserGoal.generalFitness:
          recommendations['balance'] = 'Сочетайте силовые, кардио и упражнения на гибкость';
          recommendations['consistency'] = 'Регулярность важнее интенсивности';
          break;
      }
    }
    
    return recommendations;
  }
}