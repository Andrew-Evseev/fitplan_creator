class WorkoutExercise {
  final String exerciseId;
  final int sets;
  final int reps;
  final int restTime; // в секундах
  final List<bool> completedSets;
  final String? notes; // Дополнительные заметки к упражнению
  final double? weight; // Вес для упражнения (если применимо)
  final String? tempo; // Темп выполнения (например: 2-1-2)

  WorkoutExercise({
    required this.exerciseId,
    this.sets = 3,
    this.reps = 10,
    this.restTime = 60,
    List<bool>? completedSets,
    this.notes,
    this.weight,
    this.tempo,
  }) : completedSets = completedSets ?? List.filled(sets, false);

  // Вычисляемые свойства
  bool get isCompleted => completedSets.every((set) => set);
  int get completedSetsCount => completedSets.where((set) => set).length;
  double get completionPercentage => sets > 0 ? completedSetsCount / sets : 0.0;

  // Метод для выполнения подхода
  WorkoutExercise completeSet(int setIndex, {bool completed = true}) {
    if (setIndex < 0 || setIndex >= sets) return this;
    
    final newCompletedSets = List<bool>.from(completedSets);
    newCompletedSets[setIndex] = completed;
    
    return copyWith(completedSets: newCompletedSets);
  }

  // Метод для сброса всех подходов
  WorkoutExercise resetSets() {
    return copyWith(completedSets: List.filled(sets, false));
  }

  // Проверка на одинаковые параметры (для сравнения)
  bool hasSameParameters(WorkoutExercise other) {
    return exerciseId == other.exerciseId &&
           sets == other.sets &&
           reps == other.reps &&
           restTime == other.restTime;
  }

  // Рассчет примерного времени выполнения
  int get estimatedTimeMinutes {
    const int timePerSet = 90; // секунд на подход (включая отдых)
    return (sets * timePerSet) ~/ 60;
  }

  WorkoutExercise copyWith({
    String? exerciseId,
    int? sets,
    int? reps,
    int? restTime,
    List<bool>? completedSets,
    String? notes,
    double? weight,
    String? tempo,
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restTime: restTime ?? this.restTime,
      completedSets: completedSets ?? this.completedSets,
      notes: notes ?? this.notes,
      weight: weight ?? this.weight,
      tempo: tempo ?? this.tempo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'sets': sets,
      'reps': reps,
      'restTime': restTime,
      'completedSets': completedSets,
      'notes': notes,
      'weight': weight,
      'tempo': tempo,
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
      notes: json['notes'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      tempo: json['tempo'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is WorkoutExercise &&
        other.exerciseId == exerciseId &&
        other.sets == sets &&
        other.reps == reps &&
        other.restTime == restTime &&
        other.weight == weight;
  }

  @override
  int get hashCode => Object.hash(exerciseId, sets, reps, restTime, weight);

  @override
  String toString() {
    return 'WorkoutExercise(exerciseId: $exerciseId, sets: $sets, reps: $reps, restTime: $restTime, completed: $isCompleted)';
  }
}