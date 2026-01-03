import 'workout_exercise.dart';

class WorkoutTemplate {
  final String id;
  final String name;
  final String description;
  final List<String> target;
  final String level;
  final List<String> equipmentRequired;
  final Map<String, List<WorkoutExercise>> weeklyPlan;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.target,
    required this.level,
    required this.equipmentRequired,
    required this.weeklyPlan,
  });

  factory WorkoutTemplate.fromMap(Map<String, dynamic> map) {
    final weeklyPlan = <String, List<WorkoutExercise>>{};
    
    if (map['weeklyPlan'] != null) {
      final planMap = Map<String, dynamic>.from(map['weeklyPlan']);
      for (final entry in planMap.entries) {
        final exercises = (entry.value as List)
            .map((e) => WorkoutExercise.fromMap(e))
            .toList();
        weeklyPlan[entry.key] = exercises;
      }
    }

    return WorkoutTemplate(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      target: List<String>.from(map['target'] ?? []),
      level: map['level'] ?? 'beginner',
      equipmentRequired: List<String>.from(map['equipmentRequired'] ?? []),
      weeklyPlan: weeklyPlan,
    );
  }

  Map<String, dynamic> toMap() {
    final weeklyPlanMap = <String, List<Map<String, dynamic>>>{};
    
    for (final entry in weeklyPlan.entries) {
      weeklyPlanMap[entry.key] = entry.value.map((e) => e.toMap()).toList();
    }

    return {
      'id': id,
      'name': name,
      'description': description,
      'target': target,
      'level': level,
      'equipmentRequired': equipmentRequired,
      'weeklyPlan': weeklyPlanMap,
    };
  }
}