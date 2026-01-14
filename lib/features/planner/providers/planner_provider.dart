// lib/features/planner/providers/planner_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitplan_creator/data/models/exercise.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'package:fitplan_creator/data/models/workout_plan.dart';
import 'package:fitplan_creator/data/models/workout_exercise.dart';
import 'package:fitplan_creator/data/models/training_system.dart';
import 'package:fitplan_creator/data/repositories/workout_repository.dart';
import 'package:fitplan_creator/data/repositories/training_system_repository.dart';
import 'package:fitplan_creator/features/planner/algorithms/plan_generator.dart';
import 'package:fitplan_creator/core/analytics/analytics_service.dart';

class PlannerNotifier extends StateNotifier<WorkoutPlan> {
  PlannerNotifier(
    this.workoutRepository,
    this.systemRepository,
    this.planGenerator,
  ) : _allExercises = workoutRepository.allExercises,
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
  final TrainingSystemRepository systemRepository;
  final PlanGenerator planGenerator;
  final List<Exercise> _allExercises;
  final AnalyticsService _analytics = AnalyticsService();

  Future<void> _initialize() async {
    try {
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
      final stopwatch = Stopwatch()..start();
      
      // Используем интеллектуальный генератор планов
      final plan = await planGenerator.generatePlan(prefs);
      
      stopwatch.stop();
      
      // Логируем метрику генерации
      _analytics.logPlanGeneration(
        prefs: prefs,
        system: plan.trainingSystem,
        generationTime: stopwatch.elapsed,
        success: true,
      );
      
      // Логируем выбор системы
      if (plan.trainingSystem != null) {
        _analytics.logSystemSelection(plan.trainingSystem!, prefs);
      }
      
      state = plan;
    } catch (e) {
      debugPrint('Ошибка при генерации плана: $e');
      
      // Логируем ошибку
      _analytics.logPlanGeneration(
        prefs: prefs,
        system: null,
        generationTime: const Duration(),
        success: false,
        error: e.toString(),
      );
      
      await _generateDefaultPlan();
    }
  }

  // Загрузка существующего плана
  void loadPlan(WorkoutPlan plan) {
    state = plan;
  }

  // Генерация плана по умолчанию (fallback)
  Future<void> _generateDefaultPlan() async {
    try {
      // Создаем базовые предпочтения для дефолтного плана
      final defaultPrefs = UserPreferences(
        goal: UserGoal.generalFitness,
        experienceLevel: ExperienceLevel.beginner,
        trainingLocation: TrainingLocation.bodyweight,
        availableEquipment: [Equipment.bodyweight],
        daysPerWeek: 3,
        sessionDuration: 45,
      );
      
      final plan = await planGenerator.generatePlan(defaultPrefs);
      state = plan;
    } catch (e) {
      debugPrint('Ошибка при генерации дефолтного плана: $e');
      // Ultra-fallback - минимальный план
      state = WorkoutPlan(
        id: 'minimal_plan',
        userId: 'default_user',
        name: 'Минимальный план',
        description: 'Начните с этого плана',
        workouts: [
          Workout(
            id: 'day1',
            name: 'Базовая тренировка',
            dayOfWeek: 1,
            exercises: [
              WorkoutExercise(exerciseId: 'chest_01', sets: 3, reps: 10),
              WorkoutExercise(exerciseId: 'legs_01', sets: 3, reps: 12),
            ],
            duration: 30,
            completed: false,
          ),
        ],
        createdAt: DateTime.now(),
        userPreferences: null,
      );
    }
  }

  // Получить рекомендованные системы тренировок для текущего пользователя
  List<TrainingSystemTemplate> getRecommendedSystems() {
    if (state.userPreferences == null) return [];
    return systemRepository.getRecommendedSystems(state.userPreferences!);
  }

  // Получить лучшую систему для текущего пользователя
  TrainingSystemTemplate? getBestSystem() {
    if (state.userPreferences == null) return null;
    return systemRepository.getBestSystemForUser(state.userPreferences!);
  }

  // Обновить план с новой системой тренировок
  Future<void> updateTrainingSystem(TrainingSystem system) async {
    try {
      if (state.userPreferences == null) return;
      
      // Обновляем предпочтения с новой системой
      final updatedPrefs = state.userPreferences!.copyWith(
        preferredSystem: system,
      );
      
      // Генерируем новый план
      await setUserPreferences(updatedPrefs);
    } catch (e) {
      debugPrint('Ошибка при обновлении системы тренировок: $e');
    }
  }

  // Сброс и перегенерация плана
  Future<void> resetPlan() async {
    try {
      if (state.userPreferences == null) {
        await _generateDefaultPlan();
        return;
      }
      
      // Перегенерируем план с теми же предпочтениями
      await setUserPreferences(state.userPreferences!);
    } catch (e) {
      debugPrint('Ошибка при сбросе плана: $e');
      await _generateDefaultPlan();
    }
  }

  // Получить статистику по текущей системе тренировок
  Map<String, dynamic> getSystemStatistics() {
    if (state.trainingSystem == null || state.userPreferences == null) {
      return {};
    }
    
    final system = systemRepository.getSystemByType(state.trainingSystem!);
    if (system == null) return {};
    
    final recommendations = planGenerator.getProgressionRecommendations(
      system.system,
      state.userPreferences!,
    );
    
    return {
      'system': system.system.displayName,
      'description': system.description,
      'targetAudience': system.targetAudience,
      'recommendedDays': system.recommendedDaysPerWeek,
      'recommendedDuration': system.recommendedSessionDuration,
      'progressionTips': recommendations,
      'compatibility': system.isCompatibleWith(state.userPreferences!),
    };
  }

  // Получить прогресс в текущей системе
  Map<String, dynamic> getSystemProgress() {
    final stats = getPlanStatistics();
    final systemStats = getSystemStatistics();
    
    return {
      'planProgress': stats['planProgress'],
      'workoutCompletion': stats['workoutCompletionRate'],
      'setCompletion': stats['setCompletionRate'],
      'system': systemStats['system'],
      'nextProgression': systemStats['progressionTips']?['weight'] ?? 'Увеличивайте вес постепенно',
      'estimatedTimeToGoal': _estimateTimeToGoal(),
    };
  }

  String _estimateTimeToGoal() {
    if (state.userPreferences?.goal == null) return 'Не определено';
    
    final progress = getPlanStatistics()['planProgress'] as double;
    
    if (progress < 0.3) return '4-6 недель до первых результатов';
    if (progress < 0.6) return '8-12 недель до заметных изменений';
    if (progress < 0.8) return '3-6 месяцев до достижения цели';
    return 'Поддерживайте текущий уровень';
  }

  // ============ ОСТАЛЬНЫЕ МЕТОДЫ (сохранены из предыдущей версии) ============

  // Перестановка упражнений в тренировке
  void reorderExercise({
    required String workoutId,
    required int oldIndex,
    required int newIndex,
  }) {
    try {
      final workoutIndex = state.workouts.indexWhere((w) => w.id == workoutId);
      if (workoutIndex == -1) return;
      
      final workout = state.workouts[workoutIndex];
      final exercises = [...workout.exercises];
      
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      
      final exercise = exercises.removeAt(oldIndex);
      exercises.insert(newIndex, exercise);
      
      final updatedWorkout = workout.copyWith(exercises: exercises);
      final updatedWorkouts = List<Workout>.from(state.workouts);
      updatedWorkouts[workoutIndex] = updatedWorkout;
      
      state = state.copyWith(workouts: updatedWorkouts);
    } catch (e) {
      debugPrint('Ошибка при перестановке упражнения: $e');
    }
  }

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
      final availableEquipmentNames = availableEquipment.map((e) => e.displayName).toList();
      
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
      
      // Получаем старое упражнение для логирования
      final oldExerciseId = workout.exercises[exerciseIndex].exerciseId;
      
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
      
      // Логируем замену упражнения
      _analytics.logExerciseReplacement(
        oldExerciseId,
        newExerciseId,
        'user_replacement',
      );
    } catch (e) {
      debugPrint('Ошибка при замене упражнения: $e');
    }
  }
  
  // Отправить фидбек о плане
  void submitPlanFeedback({
    required bool isPositive,
    String? comment,
  }) {
    _analytics.logPlanFeedback(
      planId: state.id,
      isPositive: isPositive,
      comment: comment,
      metadata: {
        'system': state.trainingSystem?.displayName,
        'workoutsCount': state.workouts.length,
      },
    );
  }
  
  // Сообщить о проблеме с упражнением
  void reportExerciseIssue({
    required String exerciseId,
    required String issueType,
    String? description,
  }) {
    _analytics.logExerciseIssue(
      exerciseId: exerciseId,
      issueType: issueType,
      description: description,
    );
  }
  
  // Получить статистику аналитики
  Map<String, dynamic> getAnalyticsStatistics() {
    return {
      'systemStats': _analytics.getSystemStatistics(),
      'replacementStats': _analytics.getExerciseReplacementStatistics(),
      'generationStats': _analytics.getGenerationStatistics(),
    };
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
    
    if (state.trainingSystem != null) {
      buffer.writeln('Система тренировок: ${state.trainingSystem!.displayName}');
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
      if (workout.isRestDay) {
        buffer.writeln('ДЕНЬ ОТДЫХА');
        buffer.writeln('-' * 50);
        buffer.writeln();
        continue;
      }
      
      final dayNames = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
      final dayName = workout.dayOfWeek >= 1 && workout.dayOfWeek <= 7 
          ? dayNames[workout.dayOfWeek - 1] 
          : 'День ${workout.dayOfWeek}';
      
      buffer.writeln(workout.name.toUpperCase());
      buffer.writeln('День недели: $dayName');
      buffer.writeln('Длительность: ${workout.duration} минут');
      buffer.writeln('Фокус: ${workout.focus ?? "Общая тренировка"}');
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

// Обновленные провайдеры
final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(),
);

final trainingSystemRepositoryProvider = Provider<TrainingSystemRepository>(
  (ref) => TrainingSystemRepository(),
);

final planGeneratorProvider = Provider<PlanGenerator>(
  (ref) {
    final workoutRepo = ref.watch(workoutRepositoryProvider);
    final systemRepo = ref.watch(trainingSystemRepositoryProvider);
    return PlanGenerator(systemRepo, workoutRepo);
  },
);

final plannerProvider = StateNotifierProvider<PlannerNotifier, WorkoutPlan>(
  (ref) {
    final workoutRepo = ref.watch(workoutRepositoryProvider);
    final systemRepo = ref.watch(trainingSystemRepositoryProvider);
    final planGenerator = ref.watch(planGeneratorProvider);
    return PlannerNotifier(workoutRepo, systemRepo, planGenerator);
  },
);