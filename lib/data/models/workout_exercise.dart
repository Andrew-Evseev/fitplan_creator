class WorkoutExercise {
  final String exerciseId;
  final int sets;
  final int reps;
  final int restTime; // в секундах
  final List<bool> completedSets;

  WorkoutExercise({
    required this.exerciseId,
    this.sets = 3,
    this.reps = 10,
    this.restTime = 60,
    List<bool>? completedSets,
  }) : completedSets = completedSets ?? List.filled(sets, false);

  WorkoutExercise copyWith({
    String? exerciseId,
    int? sets,
    int? reps,
    int? restTime,
    List<bool>? completedSets,
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restTime: restTime ?? this.restTime,
      completedSets: completedSets ?? this.completedSets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'sets': sets,
      'reps': reps,
      'restTime': restTime,
      'completedSets': completedSets,
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exerciseId: json['exerciseId'] as String,
      sets: json['sets'] as int? ?? 3,
      reps: json['reps'] as int? ?? 10,
      restTime: json['restTime'] as int? ?? 60,
      completedSets: (json['completedSets'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          List.filled(json['sets'] as int? ?? 3, false),
    );
  }
}