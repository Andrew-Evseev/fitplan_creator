// lib/data/models/workout_plan.dart
import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'package:fitplan_creator/data/models/workout_exercise.dart';

class Workout {
  final String id;
  final String name;
  final int dayOfWeek;
  final List<WorkoutExercise> exercises;
  final int duration; // в минутах
  final bool completed;
  final bool isRestDay;
  final String? focus;

  const Workout({
    required this.id,
    required this.name,
    required this.dayOfWeek,
    required this.exercises,
    required this.duration,
    this.completed = false,
    this.isRestDay = false,
    this.focus,
  });

  Workout copyWith({
    String? id,
    String? name,
    int? dayOfWeek,
    List<WorkoutExercise>? exercises,
    int? duration,
    bool? completed,
    bool? isRestDay,
    String? focus,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      exercises: exercises ?? this.exercises,
      duration: duration ?? this.duration,
      completed: completed ?? this.completed,
      isRestDay: isRestDay ?? this.isRestDay,
      focus: focus ?? this.focus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dayOfWeek': dayOfWeek,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'duration': duration,
      'completed': completed,
      'isRestDay': isRestDay,
      'focus': focus,
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      name: json['name'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      exercises: (json['exercises'] as List)
          .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      duration: json['duration'] as int,
      completed: json['completed'] as bool? ?? false,
      isRestDay: json['isRestDay'] as bool? ?? false,
      focus: json['focus'] as String?,
    );
  }
}

class WorkoutPlan {
  final String id;
  final String userId;
  final String name;
  final String description;
  final List<Workout> workouts;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final UserPreferences? userPreferences;
  final TrainingSystem? trainingSystem; // НОВОЕ ПОЛЕ
  final Map<String, dynamic>? metadata;

  const WorkoutPlan({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.workouts,
    required this.createdAt,
    this.updatedAt,
    this.userPreferences,
    this.trainingSystem, // НОВОЕ ПОЛЕ
    this.metadata = const {},
  });

  WorkoutPlan copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<Workout>? workouts,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserPreferences? userPreferences,
    TrainingSystem? trainingSystem, // НОВОЕ ПОЛЕ
    Map<String, dynamic>? metadata,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      workouts: workouts ?? this.workouts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userPreferences: userPreferences ?? this.userPreferences,
      trainingSystem: trainingSystem ?? this.trainingSystem, // НОВОЕ ПОЛЕ
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'workouts': workouts.map((w) => w.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'userPreferences': userPreferences?.toJson(),
      'trainingSystem': trainingSystem?.displayName, // НОВОЕ ПОЛЕ
      'metadata': metadata,
    };
  }

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      workouts: (json['workouts'] as List)
          .map((w) => Workout.fromJson(w as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
      userPreferences: json['userPreferences'] != null
          ? UserPreferences.fromJson(json['userPreferences'] as Map<String, dynamic>)
          : null,
      trainingSystem: json['trainingSystem'] != null // НОВОЕ ПОЛЕ
          ? TrainingSystem.values.firstWhere(
              (s) => s.displayName == json['trainingSystem'] as String,
              orElse: () => TrainingSystem.fullBody,
            )
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }
}