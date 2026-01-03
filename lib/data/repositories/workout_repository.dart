import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:fitplan_creator/data/models/exercise.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'package:fitplan_creator/data/models/workout_plan.dart';
import 'package:fitplan_creator/data/models/workout_template.dart';
import 'package:fitplan_creator/data/models/workout_exercise.dart';

class WorkoutRepository {
  Future<List<Exercise>> getAllExercises() async {
    try {
      // Загрузка упражнений из JSON файла
      final data = await rootBundle.loadString('assets/data/exercises.json');
      final List<dynamic> jsonList = json.decode(data);
      
      return jsonList
          .map((json) => Exercise.fromMap(json))
          .toList();
    } catch (e) {
      // Возвращаем тестовые данные, если файл не найден
      return const [  // Добавлено const
        Exercise(
          id: 'pushups',
          name: 'Отжимания',
          muscleGroup: 'chest',
          equipment: ['bodyweight'],
          difficulty: 'beginner',
          gifUrl: 'https://media.giphy.com/media/3o7TKr2uFhxjpVK3i8/giphy.gif',
          substituteIds: ['bench_press', 'chest_dips'],
          description: 'Упражнение для грудных мышц',
        ),
        Exercise(
          id: 'squats',
          name: 'Приседания',
          muscleGroup: 'legs',
          equipment: ['bodyweight'],
          difficulty: 'beginner',
          gifUrl: 'https://media.giphy.com/media/3o7TKr2uFhxjpVK3i8/giphy.gif',
          substituteIds: ['lunges', 'leg_press'],
          description: 'Базовое упражнение для ног',
        ),
      ];
    }
  }

  Future<List<WorkoutTemplate>> getAllTemplates() async {
    try {
      // Загрузка шаблонов из JSON файла
      final data = await rootBundle.loadString('assets/data/templates.json');
      final List<dynamic> jsonList = json.decode(data);
      
      return jsonList
          .map((json) => WorkoutTemplate.fromMap(json))
          .toList();
    } catch (e) {
      // Возвращаем тестовые шаблоны, если файл не найден
      return const [  // Добавлено const
        WorkoutTemplate(
          id: 'beginner_weight_loss',
          name: 'Для начинающих: похудение',
          description: 'Круговые тренировки 3 раза в неделю',
          target: ['weight_loss', 'tone'],
          level: 'beginner',
          equipmentRequired: ['bodyweight'],
          weeklyPlan: {
            'monday': [
              WorkoutExercise(exerciseId: 'pushups', sets: 3, reps: '10-12'),
              WorkoutExercise(exerciseId: 'squats', sets: 3, reps: '15-20'),
            ],
            'wednesday': [
              WorkoutExercise(exerciseId: 'pushups', sets: 3, reps: '10-12'),
              WorkoutExercise(exerciseId: 'squats', sets: 3, reps: '15-20'),
            ],
            'friday': [
              WorkoutExercise(exerciseId: 'pushups', sets: 3, reps: '10-12'),
              WorkoutExercise(exerciseId: 'squats', sets: 3, reps: '15-20'),
            ],
          },
        ),
      ];
    }
  }

  Future<WorkoutTemplate> getTemplateForUser(UserPreferences preferences) async {
    final templates = await getAllTemplates();
    
    // Простой алгоритм подбора шаблона
    for (final template in templates) {
      if (_matchesPreferences(template, preferences)) {
        return template;
      }
    }
    
    // Если не нашли подходящий, возвращаем первый шаблон для новичков
    return templates.firstWhere(
      (template) => template.level == 'beginner',
      orElse: () => templates.first,
    );
  }

  bool _matchesPreferences(WorkoutTemplate template, UserPreferences preferences) {
    // Проверка цели
    if (!template.target.contains(preferences.goal)) {
      return false;
    }
    
    // Проверка уровня
    if (template.level != preferences.level) {
      return false;
    }
    
    // Проверка оборудования
    for (final equipment in template.equipmentRequired) {
      if (!preferences.equipment.contains(equipment)) {
        return false;
      }
    }
    
    return true;
  }

  Future<List<Exercise>> getExerciseSubstitutes(String exerciseId, UserPreferences preferences) async {
    final allExercises = await getAllExercises();
    final targetExercise = allExercises.firstWhere(
      (e) => e.id == exerciseId,
      orElse: () => allExercises.first,
    );
    
    // Фильтруем упражнения по группе мышц и оборудованию
    return allExercises.where((exercise) {
      if (exercise.id == exerciseId) return false;
      
      // Та же группа мышц
      if (exercise.muscleGroup != targetExercise.muscleGroup) return false;
      
      // Доступное оборудование
      for (final equipment in exercise.equipment) {
        if (!preferences.equipment.contains(equipment)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  Future<WorkoutPlan> createUserPlan({
    required String userId,
    required UserPreferences preferences,
  }) async {
    final template = await getTemplateForUser(preferences);
    
    return WorkoutPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      templateId: template.id,
      weeklyPlan: template.weeklyPlan,
      createdAt: DateTime.now(),
    );
  }
}