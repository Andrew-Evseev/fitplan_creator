import 'workout_exercise.dart';

class WorkoutPlan {
  final String id;
  final String userId;
  final String templateId;
  final Map<String, List<WorkoutExercise>> weeklyPlan;
  final DateTime createdAt;

  const WorkoutPlan({
    required this.id,
    required this.userId,
    required this.templateId,
    required this.weeklyPlan,
    required this.createdAt,
  });

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
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

    return WorkoutPlan(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      templateId: map['templateId'] ?? '',
      weeklyPlan: weeklyPlan,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toMap() {
    final weeklyPlanMap = <String, List<Map<String, dynamic>>>{};
    
    for (final entry in weeklyPlan.entries) {
      weeklyPlanMap[entry.key] = entry.value.map((e) => e.toMap()).toList();
    }

    return {
      'id': id,
      'userId': userId,
      'templateId': templateId,
      'weeklyPlan': weeklyPlanMap,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}