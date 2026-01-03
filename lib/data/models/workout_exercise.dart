class WorkoutExercise {
  final String exerciseId;
  final int sets;
  final String reps;

  const WorkoutExercise({
    required this.exerciseId,
    required this.sets,
    required this.reps,
  });

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      exerciseId: map['exerciseId'] ?? '',
      sets: map['sets'] ?? 3,
      reps: map['reps'] ?? '10-12',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'sets': sets,
      'reps': reps,
    };
  }
}