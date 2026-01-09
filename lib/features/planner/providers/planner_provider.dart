import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitplan_creator/data/models/exercise.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'package:fitplan_creator/data/models/workout_plan.dart';
import 'package:fitplan_creator/data/models/workout_template.dart';
import 'package:fitplan_creator/data/models/workout_exercise.dart';
import 'package:fitplan_creator/data/repositories/workout_repository.dart';

class PlannerNotifier extends StateNotifier<WorkoutPlan> {
  PlannerNotifier(this.workoutRepository)
      : _allExercises = workoutRepository.allExercises,
        super(WorkoutPlan(
          id: 'temp',
          userId: 'temp',
          name: 'Мой план тренировок',
          description: 'Персональный план',
          workouts: const [],
          createdAt: DateTime.now(),
          userPreferences: null,
        )) {
    _initialize();
  }

  final WorkoutRepository workoutRepository;
  final List<Exercise> _allExercises;

  Future<void> _initialize() async {
    try {
      // Если нет предпочтений пользователя, создаем план по умолчанию
      if (state.userPreferences == null) {
        await _generateDefaultPlan();
      }
    } catch (e) {
      debugPrint('Ошибка при инициализации PlannerNotifier: $e');
    }
  }

  // Установка предпочтений пользователя и генерация плана
  Future<void> setUserPreferences(UserPreferences prefs) async {
    try {
      // Генерируем план на основе предпочтений
      await _generatePlanFromPreferences(prefs);
    } catch (e) {
      debugPrint('Ошибка при установке предпочтений: $e');
    }
  }

  // Генерация плана по умолчанию
  Future<void> _generateDefaultPlan() async {
    try {
      // Используем реальные упражнения для дефолтного плана
      final day1Exercises = [
        WorkoutExercise(exerciseId: 'chest_01', sets: 3, reps: 10),
        WorkoutExercise(exerciseId: 'legs_01', sets: 3, reps: 12),
        WorkoutExercise(exerciseId: 'abs_02', sets: 3, reps: 30),
      ];
      
      final day2Exercises = [
        WorkoutExercise(exerciseId: 'back_01', sets: 3, reps: 8),
        WorkoutExercise(exerciseId: 'arms_01', sets: 3, reps: 12),
        WorkoutExercise(exerciseId: 'abs_02', sets: 3, reps: 30),
      ];

      final workouts = [
        Workout(
          id: 'day1',
          name: 'День 1: Верх тела + Ноги',
          dayOfWeek: 1,
          exercises: day1Exercises,
          duration: 45,
          completed: false,
        ),
        Workout(
          id: 'day2',
          name: 'День 2: Спина + Руки',
          dayOfWeek: 3,
          exercises: day2Exercises,
          duration: 45,
          completed: false,
        ),
      ];

      state = WorkoutPlan(
        id: 'default_plan',
        userId: 'default_user',
        name: 'Стандартный план',
        description: 'Базовый план для новичков',
        workouts: workouts,
        createdAt: DateTime.now(),
        userPreferences: UserPreferences(
          goal: UserGoal.generalFitness,
          experienceLevel: ExperienceLevel.beginner,
          availableEquipment: [Equipment.none],
          daysPerWeek: 2,
          sessionDuration: 45,
        ),
      );
    } catch (e) {
      debugPrint('Ошибка при генерации плана по умолчанию: $e');
    }
  }

  // Генерация плана на основе предпочтений пользователя
  Future<void> _generatePlanFromPreferences(UserPreferences prefs) async {
    try {
      // Получаем шаблоны тренировок
      final templates = workoutRepository.getWorkoutTemplates();
      
      // Выбираем подходящий шаблон на основе предпочтений
      final selectedTemplate = _selectTemplateByPreferences(templates, prefs);
      
      // Создаем план тренировок
      final workouts = await _createWorkoutSchedule(selectedTemplate, prefs);
      
      // Обновляем state
      state = state.copyWith(
        workouts: workouts,
        name: _getPlanName(prefs),
        description: _getPlanDescription(prefs),
        userPreferences: prefs,
      );
    } catch (e) {
      debugPrint('Ошибка при генерации плана из предпочтений: $e');
      // В случае ошибки используем дефолтный план
      await _generateDefaultPlan();
    }
  }

  // Выбор шаблона на основе предпочтений
  WorkoutTemplate _selectTemplateByPreferences(
    List<WorkoutTemplate> templates,
    UserPreferences prefs,
  ) {
    // Логика выбора шаблона
    if (prefs.goal == UserGoal.weightLoss) {
      return templates.firstWhere(
        (t) => t.name.toLowerCase().contains('кардио') || t.name.toLowerCase().contains('фулбади'),
        orElse: () => templates.first,
      );
    } else if (prefs.goal == UserGoal.muscleGain) {
      return templates.firstWhere(
        (t) => t.name.toLowerCase().contains('фулбади'),
        orElse: () => templates.first,
      );
    } else if (prefs.goal == UserGoal.endurance) {
      return templates.firstWhere(
        (t) => t.name.toLowerCase().contains('кардио'),
        orElse: () => templates.first,
      );
    } else {
      return templates.first;
    }
  }

  // Создание расписания тренировок
  Future<List<Workout>> _createWorkoutSchedule(
    WorkoutTemplate template,
    UserPreferences prefs,
  ) async {
    final workouts = <Workout>[];
    final daysPerWeek = prefs.daysPerWeek ?? 3;
    final sessionDuration = prefs.sessionDuration ?? 45;

    // Адаптируем упражнения под доступное оборудование
    final availableExercises = _filterExercisesByEquipment(
      template.exercises,
      prefs.availableEquipment,
    );

    // Адаптируем объем тренировки под длительность
    final adaptedExercises = _adaptWorkoutVolume(
      availableExercises,
      sessionDuration,
      prefs.experienceLevel ?? ExperienceLevel.beginner,
    );

    // Создаем тренировки на неделю
    for (int day = 0; day < daysPerWeek; day++) {
      final workout = Workout(
        id: 'day_${day + 1}',
        name: 'День ${day + 1}: ${template.name}',
        dayOfWeek: day + 1,
        exercises: List.from(adaptedExercises),
        duration: sessionDuration,
        completed: false,
      );
      
      workouts.add(workout);
    }

    return workouts;
  }

  // Фильтрация упражнений по доступному оборудованию
  List<WorkoutExercise> _filterExercisesByEquipment(
    List<WorkoutExercise> exercises,
    List<Equipment> availableEquipment,
  ) {
    return exercises.where((exercise) {
      final ex = _allExercises.firstWhere(
        (e) => e.id == exercise.exerciseId,
        orElse: () => Exercise.empty(),
      );
      
      // Если у упражнения нет требований к оборудованию или оборудование доступно
      if (ex.requiredEquipment.isEmpty) return true;
      
      return ex.requiredEquipment.every(
        (equipment) => availableEquipment.any((e) => e.name == equipment),
      );
    }).toList();
  }

  // Адаптация объема тренировки под длительность и уровень
  List<WorkoutExercise> _adaptWorkoutVolume(
    List<WorkoutExercise> exercises,
    int sessionDuration,
    ExperienceLevel level,
  ) {
    final adaptedExercises = <WorkoutExercise>[];
    
    for (final exercise in exercises) {
      int sets;
      int reps;
      
      // Настройка подходов и повторений в зависимости от уровня
      switch (level) {
        case ExperienceLevel.beginner:
          sets = 3;
          reps = 10;
          break;
        case ExperienceLevel.intermediate:
          sets = 4;
          reps = 8;
          break;
        case ExperienceLevel.advanced:
          sets = 5;
          reps = 6;
          break;
      }
      
      adaptedExercises.add(exercise.copyWith(
        sets: sets,
        reps: reps,
      ));
    }
    
    return adaptedExercises;
  }

  // ============ НОВЫЙ МЕТОД ДЛЯ DRAG-AND-DROP ============

  // Перестановка упражнений в тренировке
  void reorderExercise({
    required String workoutId,
    required int oldIndex,
    required int newIndex,
  }) {
    try {
      // Находим тренировку по ID
      final workoutIndex = state.workouts.indexWhere((w) => w.id == workoutId);
      if (workoutIndex == -1) return;
      
      final workout = state.workouts[workoutIndex];
      final exercises = [...workout.exercises];
      
      // Корректируем новый индекс, если старый индекс меньше нового
      // (это нужно, потому что когда мы удаляем элемент, индексы смещаются)
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      
      // Извлекаем упражнение из старого положения и вставляем в новое
      final exercise = exercises.removeAt(oldIndex);
      exercises.insert(newIndex, exercise);
      
      // Создаем обновленную тренировку
      final updatedWorkout = workout.copyWith(exercises: exercises);
      
      // Создаем обновленный список тренировок
      final updatedWorkouts = List<Workout>.from(state.workouts);
      updatedWorkouts[workoutIndex] = updatedWorkout;
      
      // Обновляем state
      state = state.copyWith(workouts: updatedWorkouts);
    } catch (e) {
      debugPrint('Ошибка при перестановке упражнения: $e');
    }
  }

  // ============ ПУБЛИЧНЫЕ МЕТОДЫ ============

  // Получить упражнение по ID
  Exercise getExerciseById(String exerciseId) {
    try {
      return _allExercises.firstWhere(
        (e) => e.id == exerciseId,
        orElse: () => Exercise.empty(),
      );
    } catch (e) {
      debugPrint('Ошибка при получении упражнения по ID: $e');
      return Exercise.empty();
    }
  }

  // Получить все упражнения
  List<Exercise> getAllExercises() {
    return List.from(_allExercises);
  }

  // Получить альтернативные упражнения с учетом доступного оборудования
  List<Exercise> getAlternativeExercisesForExercise(String exerciseId) {
    try {
      final currentExercise = getExerciseById(exerciseId);
      if (currentExercise.id.isEmpty) return [];
      
      final availableEquipment = state.userPreferences?.availableEquipment ?? [];
      final availableEquipmentNames = availableEquipment.map((e) => e.name).toList();
      
      // Фильтруем упражнения по доступному оборудованию и группе мышц
      return _allExercises.where((exercise) {
        // Не показываем текущее упражнение
        if (exercise.id == exerciseId) return false;
        
        // Проверяем доступность оборудования
        final hasEquipment = exercise.requiredEquipment.isEmpty ||
            exercise.requiredEquipment.every((requiredEq) =>
                availableEquipmentNames.contains(requiredEq));
        
        if (!hasEquipment) return false;
        
        // Ищем упражнения на схожие группы мышц
        final currentPrimaryMuscles = currentExercise.primaryMuscleGroups;
        final exercisePrimaryMuscles = exercise.primaryMuscleGroups;
        
        // Проверяем пересечение основных групп мышц
        final hasCommonPrimary = currentPrimaryMuscles.any((muscle) => 
            exercisePrimaryMuscles.contains(muscle));
        
        // Проверяем пересечение основных и вторичных групп
        final primaryInSecondary = exercisePrimaryMuscles.any((muscle) => 
            currentExercise.secondaryMuscleGroups.contains(muscle));
        
        final secondaryInPrimary = currentPrimaryMuscles.any((muscle) => 
            exercise.secondaryMuscleGroups.contains(muscle));
        
        return hasCommonPrimary || primaryInSecondary || secondaryInPrimary;
      }).toList();
    } catch (e) {
      debugPrint('Ошибка при получении альтернативных упражнений: $e');
      return [];
    }
  }

  // Обновить параметры упражнения (подходы, повторения, отдых)
  Future<void> updateExerciseParameters({
    required String workoutId,
    required int exerciseIndex,
    required int sets,
    required int reps,
    required int restTime,
  }) async {
    try {
      final workoutIndex = state.workouts.indexWhere((w) => w.id == workoutId);
      if (workoutIndex == -1) return;
      
      final workout = state.workouts[workoutIndex];
      if (exerciseIndex >= workout.exercises.length) return;
      
      final exercise = workout.exercises[exerciseIndex];
      
      // Обновляем упражнение с новыми параметрами
      final updatedExercise = exercise.copyWith(
        sets: sets,
        reps: reps,
        restTime: restTime,
        // Сбрасываем completedSets под новый размер
        completedSets: List.filled(sets, false),
      );
      
      // Создаем обновленный список упражнений
      final updatedExercises = List<WorkoutExercise>.from(workout.exercises);
      updatedExercises[exerciseIndex] = updatedExercise;
      
      // Создаем обновленную тренировку
      final updatedWorkout = workout.copyWith(exercises: updatedExercises);
      
      // Создаем обновленный список тренировок
      final updatedWorkouts = List<Workout>.from(state.workouts);
      updatedWorkouts[workoutIndex] = updatedWorkout;
      
      // Обновляем state
      state = state.copyWith(workouts: updatedWorkouts);
    } catch (e) {
      debugPrint('Ошибка при обновлении параметров упражнения: $e');
    }
  }

  // Получение альтернативных упражнений (старый метод, для совместимости)
  List<Exercise> getAlternativeExercises(String exerciseId) {
    try {
      final currentExercise = _allExercises.firstWhere(
        (e) => e.id == exerciseId,
        orElse: () => Exercise.empty(),
      );
      
      if (currentExercise.id.isEmpty) return [];
      
      // Ищем упражнения на схожие группы мышц
      return _allExercises.where((exercise) {
        if (exercise.id == exerciseId) return false;
        
        final currentPrimary = currentExercise.primaryMuscleGroups;
        final exercisePrimary = exercise.primaryMuscleGroups;
        
        // Проверяем пересечение основных групп мышц
        return currentPrimary.any((muscle) => exercisePrimary.contains(muscle));
      }).toList();
    } catch (e) {
      debugPrint('Ошибка при получении альтернативных упражнений: $e');
      return [];
    }
  }

  // Замена упражнения в плане
  Future<void> replaceExercise({
    required String dayId,
    required int exerciseIndex,
    required String newExerciseId,
  }) async {
    try {
      // Находим тренировку по dayId
      final workoutIndex = state.workouts.indexWhere((w) => w.id == dayId);
      if (workoutIndex == -1) return;
      
      final workout = state.workouts[workoutIndex];
      if (exerciseIndex >= workout.exercises.length) return;
      
      // Создаем копию упражнения с новым ID
      final exercise = workout.exercises[exerciseIndex];
      final updatedExercise = exercise.copyWith(
        exerciseId: newExerciseId,
      );
      
      // Создаем обновленный список упражнений
      final updatedExercises = List<WorkoutExercise>.from(workout.exercises);
      updatedExercises[exerciseIndex] = updatedExercise;
      
      // Создаем обновленную тренировку
      final updatedWorkout = workout.copyWith(exercises: updatedExercises);
      
      // Создаем обновленный список тренировок
      final updatedWorkouts = List<Workout>.from(state.workouts);
      updatedWorkouts[workoutIndex] = updatedWorkout;
      
      // Обновляем state
      state = state.copyWith(workouts: updatedWorkouts);
    } catch (e) {
      debugPrint('Ошибка при замене упражнения: $e');
    }
  }

  // Обновление выполненных подходов
  Future<void> updateSetCompletion({
    required String dayId,
    required int exerciseIndex,
    required int setIndex,
    required bool completed,
  }) async {
    try {
      final workoutIndex = state.workouts.indexWhere((w) => w.id == dayId);
      if (workoutIndex == -1) return;
      
      final workout = state.workouts[workoutIndex];
      if (exerciseIndex >= workout.exercises.length) return;
      
      final exercise = workout.exercises[exerciseIndex];
      if (setIndex >= exercise.completedSets.length) return;
      
      // Обновляем массив completedSets
      final updatedCompletedSets = List<bool>.from(exercise.completedSets);
      updatedCompletedSets[setIndex] = completed;
      
      final updatedExercise = exercise.copyWith(
        completedSets: updatedCompletedSets,
      );
      
      final updatedExercises = List<WorkoutExercise>.from(workout.exercises);
      updatedExercises[exerciseIndex] = updatedExercise;
      
      final updatedWorkout = workout.copyWith(exercises: updatedExercises);
      
      // Проверяем, все ли упражнения выполнены
      final allExercisesCompleted = updatedExercises.every(
        (ex) => ex.completedSets.every((completed) => completed),
      );
      
      final finalWorkout = updatedWorkout.copyWith(completed: allExercisesCompleted);
      
      final updatedWorkouts = List<Workout>.from(state.workouts);
      updatedWorkouts[workoutIndex] = finalWorkout;
      
      state = state.copyWith(workouts: updatedWorkouts);
    } catch (e) {
      debugPrint('Ошибка при обновлении подхода: $e');
    }
  }

  // Сброс всех выполненных подходов в тренировке
  Future<void> resetWorkoutCompletion(String dayId) async {
    try {
      final workoutIndex = state.workouts.indexWhere((w) => w.id == dayId);
      if (workoutIndex == -1) return;
      
      final workout = state.workouts[workoutIndex];
      
      // Сбрасываем все completedSets в false
      final resetExercises = workout.exercises.map((exercise) {
        return exercise.copyWith(
          completedSets: List.filled(exercise.sets, false),
        );
      }).toList();
      
      final resetWorkout = workout.copyWith(
        exercises: resetExercises,
        completed: false,
      );
      
      final updatedWorkouts = List<Workout>.from(state.workouts);
      updatedWorkouts[workoutIndex] = resetWorkout;
      
      state = state.copyWith(workouts: updatedWorkouts);
    } catch (e) {
      debugPrint('Ошибка при сбросе тренировки: $e');
    }
  }

  // Получение прогресса выполнения плана
  double getProgress() {
    if (state.workouts.isEmpty) return 0.0;
    
    final completedWorkouts = state.workouts
        .where((workout) => workout.completed)
        .length;
    
    return completedWorkouts / state.workouts.length;
  }

  // Вспомогательные методы
  String _getPlanName(UserPreferences prefs) {
    if (prefs.goal != null) {
      return 'План: ${prefs.goal!.displayName}';
    }
    return 'Персональный план тренировок';
  }

  String _getPlanDescription(UserPreferences prefs) {
    final parts = <String>[];
    
    if (prefs.experienceLevel != null) {
      parts.add('Уровень: ${prefs.experienceLevel!.displayName}');
    }
    
    if (prefs.daysPerWeek != null) {
      parts.add('${prefs.daysPerWeek} дней/неделя');
    }
    
    if (prefs.sessionDuration != null) {
      parts.add('${prefs.sessionDuration} мин/тренировка');
    }
    
    if (prefs.availableEquipment.isNotEmpty) {
      final equipmentNames = prefs.availableEquipment
          .take(3)
          .map((e) => e.displayName)
          .join(', ');
      parts.add('Оборудование: $equipmentNames${prefs.availableEquipment.length > 3 ? '...' : ''}');
    }
    
    return parts.join(' • ');
  }

  // Сброс плана к начальному состоянию
  Future<void> resetPlan() async {
    if (state.userPreferences != null) {
      await _generatePlanFromPreferences(state.userPreferences!);
    } else {
      await _generateDefaultPlan();
    }
  }

  // Получить общее количество выполненных подходов
  int getTotalCompletedSets() {
    return state.workouts.fold(0, (total, workout) {
      return total + workout.exercises.fold(0, (sum, exercise) {
        return sum + exercise.completedSets.where((c) => c).length;
      });
    });
  }

  // Получить общее количество подходов в плана
  int getTotalSets() {
    return state.workouts.fold(0, (total, workout) {
      return total + workout.exercises.fold(0, (sum, exercise) => sum + exercise.sets);
    });
  }

  // Получить статистику по плану
  Map<String, dynamic> getPlanStatistics() {
    final totalSets = getTotalSets();
    final completedSets = getTotalCompletedSets();
    final completedWorkouts = state.workouts.where((w) => w.completed).length;
    final totalWorkouts = state.workouts.length;
    
    return {
      'totalWorkouts': totalWorkouts,
      'completedWorkouts': completedWorkouts,
      'workoutCompletionRate': totalWorkouts > 0 ? completedWorkouts / totalWorkouts : 0.0,
      'totalSets': totalSets,
      'completedSets': completedSets,
      'setCompletionRate': totalSets > 0 ? completedSets / totalSets : 0.0,
      'planProgress': getProgress(),
    };
  }

  // Добавить новое упражнение в тренировку
  Future<void> addExerciseToWorkout({
    required String workoutId,
    required String exerciseId,
    int sets = 3,
    int reps = 10,
    int restTime = 60,
  }) async {
    try {
      final workoutIndex = state.workouts.indexWhere((w) => w.id == workoutId);
      if (workoutIndex == -1) return;
      
      final workout = state.workouts[workoutIndex];
      
      // Создаем новое упражнение
      final newExercise = WorkoutExercise(
        exerciseId: exerciseId,
        sets: sets,
        reps: reps,
        restTime: restTime,
      );
      
      // Добавляем к существующим упражнениям
      final updatedExercises = List<WorkoutExercise>.from(workout.exercises);
      updatedExercises.add(newExercise);
      
      // Обновляем тренировку
      final updatedWorkout = workout.copyWith(
        exercises: updatedExercises,
        duration: workout.duration + 15,
      );
      
      // Обновляем список тренировок
      final updatedWorkouts = List<Workout>.from(state.workouts);
      updatedWorkouts[workoutIndex] = updatedWorkout;
      
      // Обновляем state
      state = state.copyWith(workouts: updatedWorkouts);
    } catch (e) {
      debugPrint('Ошибка при добавлении упражнения: $e');
    }
  }

  // Удалить упражнение из тренировки
  Future<void> removeExerciseFromWorkout({
    required String workoutId,
    required int exerciseIndex,
  }) async {
    try {
      final workoutIndex = state.workouts.indexWhere((w) => w.id == workoutId);
      if (workoutIndex == -1) return;
      
      final workout = state.workouts[workoutIndex];
      if (exerciseIndex >= workout.exercises.length) return;
      
      // Удаляем упражнение
      final updatedExercises = List<WorkoutExercise>.from(workout.exercises);
      updatedExercises.removeAt(exerciseIndex);
      
      // Обновляем тренировку
      final updatedWorkout = workout.copyWith(
        exercises: updatedExercises,
        duration: workout.duration > 15 ? workout.duration - 15 : 30,
      );
      
      // Обновляем список тренировок
      final updatedWorkouts = List<Workout>.from(state.workouts);
      updatedWorkouts[workoutIndex] = updatedWorkout;
      
      // Обновляем state
      state = state.copyWith(workouts: updatedWorkouts);
    } catch (e) {
      debugPrint('Ошибка при удалении упражнения: $e');
    }
  }

  // Перемешать упражнения в тренировке
  Future<void> shuffleWorkoutExercises(String workoutId) async {
    try {
      final workoutIndex = state.workouts.indexWhere((w) => w.id == workoutId);
      if (workoutIndex == -1) return;
      
      final workout = state.workouts[workoutIndex];
      
      // Создаем копию списка упражнений и перемешиваем
      final shuffledExercises = List<WorkoutExercise>.from(workout.exercises);
      shuffledExercises.shuffle();
      
      // Обновляем тренировку
      final updatedWorkout = workout.copyWith(exercises: shuffledExercises);
      
      // Обновляем список тренировок
      final updatedWorkouts = List<Workout>.from(state.workouts);
      updatedWorkouts[workoutIndex] = updatedWorkout;
      
      // Обновляем state
      state = state.copyWith(workouts: updatedWorkouts);
    } catch (e) {
      debugPrint('Ошибка при перемешивании упражнений: $e');
    }
  }

  // Экспорт плана в текстовый формат
  String exportPlanToText() {
    final buffer = StringBuffer();
    
    buffer.writeln('ПЛАН ТРЕНИРОВОК');
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln('Название: ${state.name}');
    buffer.writeln('Описание: ${state.description}');
    buffer.writeln('Создан: ${state.createdAt.toLocal().toString().split(' ')[0]}');
    
    if (state.userPreferences != null) {
      buffer.writeln();
      buffer.writeln('ПАРАМЕТРЫ ПОЛЬЗОВАТЕЛЯ:');
      buffer.writeln('Цель: ${state.userPreferences!.goal?.displayName ?? "Не указано"}');
      buffer.writeln('Уровень: ${state.userPreferences!.experienceLevel?.displayName ?? "Не указано"}');
      buffer.writeln('Дней в неделю: ${state.userPreferences!.daysPerWeek ?? "Не указано"}');
      buffer.writeln('Длительность тренировки: ${state.userPreferences!.sessionDuration ?? "Не указано"} мин');
      buffer.writeln('Оборудование: ${state.userPreferences!.availableEquipment.map((e) => e.displayName).join(", ")}');
    }
    
    buffer.writeln();
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    final statistics = getPlanStatistics();
    buffer.writeln('СТАТИСТИКА:');
    buffer.writeln('Прогресс плана: ${(statistics['planProgress']! * 100).toStringAsFixed(1)}%');
    buffer.writeln('Завершено тренировок: ${statistics['completedWorkouts']}/${statistics['totalWorkouts']}');
    buffer.writeln('Завершено подходов: ${statistics['completedSets']}/${statistics['totalSets']}');
    
    buffer.writeln();
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    for (final workout in state.workouts) {
      final dayNames = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
      final dayName = workout.dayOfWeek >= 1 && workout.dayOfWeek <= 7 
          ? dayNames[workout.dayOfWeek - 1] 
          : 'День ${workout.dayOfWeek}';
      
      buffer.writeln(workout.name.toUpperCase());
      buffer.writeln('День недели: $dayName');
      buffer.writeln('Длительность: ${workout.duration} минут');
      buffer.writeln('Статус: ${workout.completed ? "✅ Выполнено" : "⏳ Ожидание"}');
      buffer.writeln();
      
      for (int i = 0; i < workout.exercises.length; i++) {
        final exercise = workout.exercises[i];
        final exDetails = getExerciseById(exercise.exerciseId);
        
        if (exDetails.id.isNotEmpty) {
          buffer.writeln('${i + 1}. ${exDetails.name}');
          buffer.writeln('   Подходы: ${exercise.sets} × ${exercise.reps > 0 ? exercise.reps : "до утомления"}');
          buffer.writeln('   Отдых: ${exercise.restTime} сек');
          buffer.writeln('   Выполнено: ${exercise.completedSets.where((c) => c).length}/${exercise.sets}');
          
          if (exDetails.description.isNotEmpty) {
            buffer.writeln('   Описание: ${exDetails.description}');
          }
          
          buffer.writeln();
        }
      }
      
      buffer.writeln('─' * 50);
      buffer.writeln();
    }
    
    buffer.writeln('Желаем продуктивных тренировок! 💪');
    
    return buffer.toString();
  }
}

// Провайдеры
final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(),
);

final plannerProvider = StateNotifierProvider<PlannerNotifier, WorkoutPlan>(
  (ref) {
    final repository = ref.watch(workoutRepositoryProvider);
    return PlannerNotifier(repository);
  },
);