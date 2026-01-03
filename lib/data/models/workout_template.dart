import 'workout_exercise.dart';

class WorkoutTemplate {
  final String id;
  final String name;
  final String description;
  final List<WorkoutExercise> exercises;
  final int duration; // в минутах
  final String difficulty;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.exercises,
    required this.duration,
    required this.difficulty,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'duration': duration,
      'difficulty': difficulty,
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
    );
  }
}