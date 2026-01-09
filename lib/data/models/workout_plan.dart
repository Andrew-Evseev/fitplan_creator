import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'workout_exercise.dart';

class Workout {
  final String id;
  final String name;
  final int dayOfWeek; // 1-7, где 1 = понедельник
  final List<WorkoutExercise> exercises;
  final int duration; // в минутах
  final bool completed;
  final String? notes;
  final DateTime? completedAt;

  const Workout({
    required this.id,
    required this.name,
    required this.dayOfWeek,
    required this.exercises,
    required this.duration,
    this.completed = false,
    this.notes,
    this.completedAt,
  });

  // Вычисляемые свойства
  int get totalSets => exercises.fold(0, (sum, exercise) => sum + exercise.sets);
  int get completedSets => exercises.fold(0, (sum, exercise) => sum + exercise.completedSetsCount);
  double get completionPercentage => totalSets > 0 ? completedSets / totalSets : 0.0;
  
  List<String> get muscleGroups {
    final groups = <String>{};
    for (final exercise in exercises) {
      // Здесь нужно будет получить Exercise из репозитория для групп мышц
      // Временная реализация - возвращаем пустой список
      // TODO: Добавить метод для получения групп мышц упражнения
    }
    return groups.toList();
  }

  // Получить день недели как строку
  String get dayOfWeekName {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return dayOfWeek >= 1 && dayOfWeek <= 7 ? days[dayOfWeek - 1] : 'День $dayOfWeek';
  }

  // Полное название дня недели
  String get fullDayOfWeekName {
    const days = [
      'Понедельник', 'Вторник', 'Среда', 
      'Четверг', 'Пятница', 'Суббота', 'Воскресенье'
    ];
    return dayOfWeek >= 1 && dayOfWeek <= 7 ? days[dayOfWeek - 1] : 'День $dayOfWeek';
  }

  // Пометить тренировку как выполненную
  Workout markAsCompleted({String? notes}) {
    final now = DateTime.now();
    return copyWith(
      completed: true,
      completedAt: now,
      notes: notes ?? this.notes,
    );
  }

  // Сбросить статус выполнения
  Workout resetCompletion() {
    final resetExercises = exercises.map((e) => e.resetSets()).toList();
    return copyWith(
      completed: false,
      completedAt: null,
      exercises: resetExercises,
    );
  }

  // Проверить, доступна ли тренировка сегодня
  bool isAvailableToday(int currentDay) {
    return dayOfWeek == currentDay;
  }

  Workout copyWith({
    String? id,
    String? name,
    int? dayOfWeek,
    List<WorkoutExercise>? exercises,
    int? duration,
    bool? completed,
    String? notes,
    DateTime? completedAt,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      exercises: exercises ?? this.exercises,
      duration: duration ?? this.duration,
      completed: completed ?? this.completed,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
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
      'notes': notes,
      'completedAt': completedAt?.toIso8601String(),
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
      notes: json['notes'] as String?,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Workout && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
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
  final int version; // Версия плана для отслеживания изменений
  final bool isActive; // Активен ли план сейчас

  const WorkoutPlan({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.workouts,
    required this.createdAt,
    this.updatedAt,
    this.userPreferences,
    this.version = 1,
    this.isActive = true,
  });

  // Вычисляемые свойства
  int get totalWorkouts => workouts.length;
  int get completedWorkouts => workouts.where((w) => w.completed).length;
  double get completionPercentage => totalWorkouts > 0 ? completedWorkouts / totalWorkouts : 0.0;
  
  int get totalExercises => workouts.fold(0, (sum, workout) => sum + workout.exercises.length);
  int get totalSets => workouts.fold(0, (sum, workout) => sum + workout.totalSets);
  int get completedSets => workouts.fold(0, (sum, workout) => sum + workout.completedSets);
  
  // Получить тренировку по дню недели
  Workout? getWorkoutByDay(int dayOfWeek) {
    return workouts.firstWhere(
      (workout) => workout.dayOfWeek == dayOfWeek,
      orElse: () => workouts.firstWhere(
        (workout) => true,
        orElse: () => workouts.isNotEmpty ? workouts.first : Workout(
          id: 'empty',
          name: 'Нет тренировки',
          dayOfWeek: dayOfWeek,
          exercises: [],
          duration: 0,
        ),
      ),
    );
  }

  // Получить следующую тренировку
  Workout? getNextWorkout(int currentDay) {
    final sortedWorkouts = List<Workout>.from(workouts)
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    
    // Ищем тренировку сегодня или позже
    for (final workout in sortedWorkouts) {
      if (workout.dayOfWeek >= currentDay && !workout.completed) {
        return workout;
      }
    }
    
    // Если не нашли, ищем первую невыполненную тренировку
    for (final workout in sortedWorkouts) {
      if (!workout.completed) {
        return workout;
      }
    }
    
    // Если все тренировки выполнены или список пуст, возвращаем первую или null
    return sortedWorkouts.isEmpty ? null : sortedWorkouts.first;
  }

  // Получить статистику плана
  Map<String, dynamic> getStatistics() {
    return {
      'totalWorkouts': totalWorkouts,
      'completedWorkouts': completedWorkouts,
      'completionPercentage': completionPercentage,
      'totalExercises': totalExercises,
      'totalSets': totalSets,
      'completedSets': completedSets,
      'activeDays': workouts.map((w) => w.dayOfWeek).toSet().length,
      'isActive': isActive,
      'version': version,
    };
  }

  // Активировать/деактивировать план
  WorkoutPlan setActive(bool active) {
    return copyWith(
      isActive: active,
      updatedAt: DateTime.now(),
    );
  }

  // Обновить версию плана
  WorkoutPlan incrementVersion() {
    return copyWith(
      version: version + 1,
      updatedAt: DateTime.now(),
    );
  }

  WorkoutPlan copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<Workout>? workouts,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserPreferences? userPreferences,
    int? version,
    bool? isActive,
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
      version: version ?? this.version,
      isActive: isActive ?? this.isActive,
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
      'updatedAt': updatedAt?.toIso8601String(),
      'userPreferences': userPreferences?.toJson(),
      'version': version,
      'isActive': isActive,
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
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      userPreferences: json['userPreferences'] != null
          ? UserPreferences.fromJson(
              json['userPreferences'] as Map<String, dynamic>)
          : null,
      version: json['version'] as int? ?? 1,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutPlan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WorkoutPlan(id: $id, name: $name, workouts: $totalWorkouts, active: $isActive)';
  }
}