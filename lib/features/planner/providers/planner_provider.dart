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
      : super(WorkoutPlan(
          id: 'temp',
          userId: 'temp',
          name: 'Мой план тренировок',
          description: 'Персональный план',
          workouts: [],
          createdAt: DateTime.now(),
          userPreferences: null,
        )) {
    _initialize();
  }

  final WorkoutRepository workoutRepository;
  late List<Exercise> _allExercises;

  Future<void> _initialize() async {
    try {
      _allExercises = workoutRepository.getAllExercises();
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
      final defaultPlan = workoutRepository.getWorkoutPlan();
      state = defaultPlan.copyWith(
        userPreferences: UserPreferences(
          goal: UserGoal.generalFitness,
          experienceLevel: ExperienceLevel.beginner,
          availableEquipment: [Equipment.none],
          daysPerWeek: 3,
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

  // Получение альтернативных упражнений
  List<Exercise> getAlternativeExercises(String exerciseId) {
    try {
      final currentExercise = _allExercises.firstWhere(
        (e) => e.id == exerciseId,
        orElse: () => Exercise.empty(),
      );
      
      if (currentExercise.id.isEmpty) return [];
      
      // Ищем упражнения на ту же группу мышц
      return _allExercises.where((exercise) {
        return exercise.id != exerciseId &&
            exercise.primaryMuscleGroup == currentExercise.primaryMuscleGroup;
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
      final updatedExercise = workout.exercises[exerciseIndex].copyWith(
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

  // Экспорт плана в текстовый формат
  String exportPlanToText() {
    final buffer = StringBuffer();
    
    buffer.writeln('ПЛАН ТРЕНИРОВОК');
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln('Название: ${state.name}');
    buffer.writeln('Описание: ${state.description}');
    buffer.writeln('Создан: ${state.createdAt.toLocal().toString().split(' ')[0]}');
    buffer.writeln();
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    for (final workout in state.workouts) {
      buffer.writeln(workout.name.toUpperCase());
      buffer.writeln('Длительность: ${workout.duration} минут');
      buffer.writeln('Статус: ${workout.completed ? "✅ Выполнено" : "⏳ Ожидание"}');
      buffer.writeln();
      
      for (int i = 0; i < workout.exercises.length; i++) {
        final exercise = workout.exercises[i];
        final exDetails = _allExercises.firstWhere(
          (e) => e.id == exercise.exerciseId,
          orElse: () => Exercise.empty(),
        );
        
        if (exDetails.id.isNotEmpty) {
          buffer.writeln('${i + 1}. ${exDetails.name}');
          buffer.writeln('   Подходы: ${exercise.sets} × ${exercise.reps > 0 ? exercise.reps : "до утомления"}');
          buffer.writeln('   Отдых: ${exercise.restTime} сек');
          buffer.writeln('   Выполнено: ${exercise.completedSets.where((c) => c).length}/${exercise.sets}');
          buffer.writeln();
        }
      }
      
      buffer.writeln('─' * 50);
      buffer.writeln();
    }
    
    buffer.writeln('Общий прогресс: ${(getProgress() * 100).toStringAsFixed(1)}%');
    
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