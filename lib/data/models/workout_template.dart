import 'workout_exercise.dart';

class WorkoutTemplate {
  final String id;
  final String name;
  final String description;
  final List<WorkoutExercise> exercises;
  final int duration; // в минутах
  final String difficulty;
  final List<String> targetMuscleGroups;
  final List<String> requiredEquipment;
  final int daysPerWeek;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.exercises,
    required this.duration,
    required this.difficulty,
    this.targetMuscleGroups = const [],
    this.requiredEquipment = const [],
    this.daysPerWeek = 3,
  });

  // Для генерации тренировочного плана из шаблона
  List<WorkoutExercise> getExercisesForDay(int dayIndex) {
    if (exercises.isEmpty) return [];
    
    // Простая логика распределения упражнений по дням
    final exercisesPerDay = (exercises.length / daysPerWeek).ceil();
    final start = dayIndex * exercisesPerDay;
    final end = (start + exercisesPerDay) < exercises.length 
        ? start + exercisesPerDay 
        : exercises.length;
    
    if (start >= exercises.length) return [];
    return exercises.sublist(start, end);
  }

  // Проверка совместимости с оборудованием пользователя
  bool isCompatibleWithEquipment(List<String> availableEquipment) {
    if (requiredEquipment.isEmpty) return true;
    
    return requiredEquipment.every((equipment) => 
        availableEquipment.contains(equipment));
  }

  // Проверка соответствия уровню сложности
  bool matchesDifficulty(String userLevel) {
    final difficultyOrder = ['beginner', 'intermediate', 'advanced'];
    final templateIndex = difficultyOrder.indexOf(difficulty);
    final userIndex = difficultyOrder.indexOf(userLevel);
    
    if (templateIndex == -1 || userIndex == -1) return false;
    
    // Пользователь может взять шаблон своего уровня или на уровень ниже
    return userIndex >= templateIndex;
  }

  WorkoutTemplate copyWith({
    String? id,
    String? name,
    String? description,
    List<WorkoutExercise>? exercises,
    int? duration,
    String? difficulty,
    List<String>? targetMuscleGroups,
    List<String>? requiredEquipment,
    int? daysPerWeek,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      duration: duration ?? this.duration,
      difficulty: difficulty ?? this.difficulty,
      targetMuscleGroups: targetMuscleGroups ?? this.targetMuscleGroups,
      requiredEquipment: requiredEquipment ?? this.requiredEquipment,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'duration': duration,
      'difficulty': difficulty,
      'targetMuscleGroups': targetMuscleGroups,
      'requiredEquipment': requiredEquipment,
      'daysPerWeek': daysPerWeek,
    };
  }

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      duration: json['duration'] as int,
      difficulty: json['difficulty'] as String,
      targetMuscleGroups: (json['targetMuscleGroups'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      requiredEquipment: (json['requiredEquipment'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      daysPerWeek: json['daysPerWeek'] as int? ?? 3,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutTemplate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}