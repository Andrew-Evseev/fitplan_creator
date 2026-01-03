import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'workout_exercise.dart';

class Workout {
  final String id;
  final String name;
  final int dayOfWeek;
  final List<WorkoutExercise> exercises;
  final int duration; // в минутах
  final bool completed;

  const Workout({
    required this.id,
    required this.name,
    required this.dayOfWeek,
    required this.exercises,
    required this.duration,
    this.completed = false,
  });

  Workout copyWith({
    String? id,
    String? name,
    int? dayOfWeek,
    List<WorkoutExercise>? exercises,
    int? duration,
    bool? completed,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      exercises: exercises ?? this.exercises,
      duration: duration ?? this.duration,
      completed: completed ?? this.completed,
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
      duration: json['duration'] as int? ?? 45,
      completed: json['completed'] as bool? ?? false,
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
  final UserPreferences? userPreferences;

  const WorkoutPlan({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.workouts,
    required this.createdAt,
    this.userPreferences,
  });

  WorkoutPlan copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<Workout>? workouts,
    DateTime? createdAt,
    UserPreferences? userPreferences,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      workouts: workouts ?? this.workouts,
      createdAt: createdAt ?? this.createdAt,
      userPreferences: userPreferences ?? this.userPreferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'workouts': workouts.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'userPreferences': userPreferences?.toJson(),
    };
  }

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      workouts: (json['workouts'] as List)
          .map((e) => Workout.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      userPreferences: json['userPreferences'] != null
          ? UserPreferences.fromJson(
              json['userPreferences'] as Map<String, dynamic>)
          : null,
    );
  }
}