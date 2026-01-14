// lib/features/profile/models/user_profile.dart
import 'package:fitplan_creator/data/models/workout_plan.dart';

class UserProfile {
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final DateTime joinDate;
  final UserStats stats;
  final UserSettings settings;
  final List<WorkoutHistory> workoutHistory;
  final List<SavedPlan> savedPlans; // Сохраненные планы тренировок

  UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    required this.joinDate,
    required this.stats,
    required this.settings,
    required this.workoutHistory,
    required this.savedPlans,
  });

  factory UserProfile.initial(String id, String name) {
    return UserProfile(
      id: id,
      name: name,
      joinDate: DateTime.now(),
      stats: UserStats.initial(),
      settings: UserSettings.defaultSettings(),
      workoutHistory: [],
      savedPlans: [],
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    DateTime? joinDate,
    UserStats? stats,
    UserSettings? settings,
    List<WorkoutHistory>? workoutHistory,
    List<SavedPlan>? savedPlans,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinDate: joinDate ?? this.joinDate,
      stats: stats ?? this.stats,
      settings: settings ?? this.settings,
      workoutHistory: workoutHistory ?? this.workoutHistory,
      savedPlans: savedPlans ?? this.savedPlans,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'joinDate': joinDate.toIso8601String(),
      'stats': stats.toMap(),
      'settings': settings.toMap(),
      'workoutHistory': workoutHistory.map((h) => h.toMap()).toList(),
      'savedPlans': savedPlans.map((p) => p.toMap()).toList(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      joinDate: DateTime.parse(map['joinDate'] as String),
      stats: UserStats.fromMap(map['stats'] as Map<String, dynamic>),
      settings: UserSettings.fromMap(map['settings'] as Map<String, dynamic>),
      workoutHistory: (map['workoutHistory'] as List)
          .map((h) => WorkoutHistory.fromMap(h as Map<String, dynamic>))
          .toList(),
      savedPlans: (map['savedPlans'] as List? ?? [])
          .map((p) => SavedPlan.fromMap(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UserStats {
  final int totalWorkouts;
  final int totalExercises;
  final int totalMinutes;
  final int currentStreak;
  final int maxStreak;
  final Map<String, int> muscleGroupDistribution;
  final double averageWorkoutTime;

  UserStats({
    required this.totalWorkouts,
    required this.totalExercises,
    required this.totalMinutes,
    required this.currentStreak,
    required this.maxStreak,
    required this.muscleGroupDistribution,
    required this.averageWorkoutTime,
  });

  factory UserStats.initial() {
    return UserStats(
      totalWorkouts: 0,
      totalExercises: 0,
      totalMinutes: 0,
      currentStreak: 0,
      maxStreak: 0,
      muscleGroupDistribution: {},
      averageWorkoutTime: 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalWorkouts': totalWorkouts,
      'totalExercises': totalExercises,
      'totalMinutes': totalMinutes,
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
      'muscleGroupDistribution': muscleGroupDistribution,
      'averageWorkoutTime': averageWorkoutTime,
    };
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      totalWorkouts: map['totalWorkouts'] as int,
      totalExercises: map['totalExercises'] as int,
      totalMinutes: map['totalMinutes'] as int,
      currentStreak: map['currentStreak'] as int,
      maxStreak: map['maxStreak'] as int,
      muscleGroupDistribution: Map<String, int>.from(map['muscleGroupDistribution'] as Map),
      averageWorkoutTime: (map['averageWorkoutTime'] as num).toDouble(),
    );
  }

  UserStats copyWith({
    int? totalWorkouts,
    int? totalExercises,
    int? totalMinutes,
    int? currentStreak,
    int? maxStreak,
    Map<String, int>? muscleGroupDistribution,
    double? averageWorkoutTime,
  }) {
    return UserStats(
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalExercises: totalExercises ?? this.totalExercises,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      muscleGroupDistribution: muscleGroupDistribution ?? this.muscleGroupDistribution,
      averageWorkoutTime: averageWorkoutTime ?? this.averageWorkoutTime,
    );
  }
}

class WorkoutHistory {
  final String id;
  final String planName;
  final DateTime date;
  final int duration;
  final int exercisesCount;
  final bool completed;

  WorkoutHistory({
    required this.id,
    required this.planName,
    required this.date,
    required this.duration,
    required this.exercisesCount,
    required this.completed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planName': planName,
      'date': date.toIso8601String(),
      'duration': duration,
      'exercisesCount': exercisesCount,
      'completed': completed,
    };
  }

  factory WorkoutHistory.fromMap(Map<String, dynamic> map) {
    return WorkoutHistory(
      id: map['id'] as String,
      planName: map['planName'] as String,
      date: DateTime.parse(map['date'] as String),
      duration: map['duration'] as int,
      exercisesCount: map['exercisesCount'] as int,
      completed: map['completed'] as bool,
    );
  }
}

class UserSettings {
  final bool notificationsEnabled;
  final bool darkMode;
  final String language;
  final String units;
  final bool autoSave;
  final bool showTutorials;

  UserSettings({
    required this.notificationsEnabled,
    required this.darkMode,
    required this.language,
    required this.units,
    required this.autoSave,
    required this.showTutorials,
  });

  factory UserSettings.defaultSettings() {
    return UserSettings(
      notificationsEnabled: true,
      darkMode: false,
      language: 'ru',
      units: 'metric',
      autoSave: true,
      showTutorials: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'darkMode': darkMode,
      'language': language,
      'units': units,
      'autoSave': autoSave,
      'showTutorials': showTutorials,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      notificationsEnabled: map['notificationsEnabled'] as bool,
      darkMode: map['darkMode'] as bool,
      language: map['language'] as String,
      units: map['units'] as String,
      autoSave: map['autoSave'] as bool,
      showTutorials: map['showTutorials'] as bool,
    );
  }

  UserSettings copyWith({
    bool? notificationsEnabled,
    bool? darkMode,
    String? language,
    String? units,
    bool? autoSave,
    bool? showTutorials,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      units: units ?? this.units,
      autoSave: autoSave ?? this.autoSave,
      showTutorials: showTutorials ?? this.showTutorials,
    );
  }
}

// Модель сохраненного плана
class SavedPlan {
  final String planId;
  final String name;
  final String description;
  final DateTime savedAt;
  final DateTime? planCreatedAt;
  final String? trainingSystem;
  final int workoutsCount;
  final Map<String, dynamic> planData; // Полные данные плана в JSON формате

  SavedPlan({
    required this.planId,
    required this.name,
    required this.description,
    required this.savedAt,
    this.planCreatedAt,
    this.trainingSystem,
    required this.workoutsCount,
    required this.planData,
  });

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'name': name,
      'description': description,
      'savedAt': savedAt.toIso8601String(),
      'planCreatedAt': planCreatedAt?.toIso8601String(),
      'trainingSystem': trainingSystem,
      'workoutsCount': workoutsCount,
      'planData': planData,
    };
  }

  factory SavedPlan.fromMap(Map<String, dynamic> map) {
    return SavedPlan(
      planId: map['planId'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      savedAt: DateTime.parse(map['savedAt'] as String),
      planCreatedAt: map['planCreatedAt'] != null
          ? DateTime.parse(map['planCreatedAt'] as String)
          : null,
      trainingSystem: map['trainingSystem'] as String?,
      workoutsCount: map['workoutsCount'] as int,
      planData: Map<String, dynamic>.from(map['planData'] as Map),
    );
  }

  SavedPlan copyWith({
    String? planId,
    String? name,
    String? description,
    DateTime? savedAt,
    DateTime? planCreatedAt,
    String? trainingSystem,
    int? workoutsCount,
    Map<String, dynamic>? planData,
  }) {
    return SavedPlan(
      planId: planId ?? this.planId,
      name: name ?? this.name,
      description: description ?? this.description,
      savedAt: savedAt ?? this.savedAt,
      planCreatedAt: planCreatedAt ?? this.planCreatedAt,
      trainingSystem: trainingSystem ?? this.trainingSystem,
      workoutsCount: workoutsCount ?? this.workoutsCount,
      planData: planData ?? this.planData,
    );
  }
}