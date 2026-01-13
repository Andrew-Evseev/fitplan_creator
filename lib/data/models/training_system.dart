// lib/data/models/training_system.dart
import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'package:fitplan_creator/data/models/workout_exercise.dart';

// Модель для шаблона тренировочной системы
class TrainingSystemTemplate {
  final TrainingSystem system;
  final String name;
  final String description;
  final String targetAudience;
  final UserGoal primaryGoal;
  final List<UserGoal> compatibleGoals;
  final ExperienceLevel minExperienceLevel;
  final List<ExperienceLevel> compatibleLevels;
  final BodyType? recommendedBodyType;
  final int recommendedDaysPerWeek;
  final int recommendedSessionDuration; // в минутах
  final TrainingLocation recommendedLocation;
  final List<Equipment> requiredEquipment;
  final Map<int, WorkoutDayTemplate> weeklyStructure; // день недели → шаблон дня
  final Map<String, dynamic> progressionRules;
  final Map<String, dynamic> adaptationRules;
  final int priority; // приоритет при автоматическом выборе (1-10)

  const TrainingSystemTemplate({
    required this.system,
    required this.name,
    required this.description,
    required this.targetAudience,
    required this.primaryGoal,
    this.compatibleGoals = const [],
    required this.minExperienceLevel,
    this.compatibleLevels = const [],
    this.recommendedBodyType,
    required this.recommendedDaysPerWeek,
    required this.recommendedSessionDuration,
    required this.recommendedLocation,
    this.requiredEquipment = const [],
    required this.weeklyStructure,
    this.progressionRules = const {},
    this.adaptationRules = const {},
    this.priority = 5,
  });

  // Проверка совместимости с профилем пользователя
  bool isCompatibleWith(UserPreferences prefs) {
    // Проверка цели
    if (!compatibleGoals.contains(prefs.goal) && primaryGoal != prefs.goal) {
      return false;
    }

    // Проверка уровня опыта
    if (!compatibleLevels.contains(prefs.experienceLevel) &&
        _getExperienceLevelValue(prefs.experienceLevel) < 
        _getExperienceLevelValue(minExperienceLevel)) {
      return false;
    }

    // Проверка доступности оборудования
    if (!_hasRequiredEquipment(prefs.availableEquipment)) {
      return false;
    }

    // Проверка места тренировок
    if (prefs.trainingLocation != recommendedLocation &&
        recommendedLocation != TrainingLocation.gym) {
      // Гим принимает все, другие локации более специфичны
      return false;
    }

    return true;
  }

  // Получить числовое значение уровня опыта
  int _getExperienceLevelValue(ExperienceLevel? level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return 1;
      case ExperienceLevel.intermediate:
        return 2;
      case ExperienceLevel.advanced:
        return 3;
      default:
        return 0;
    }
  }

  // Проверить наличие необходимого оборудования
  bool _hasRequiredEquipment(List<Equipment> availableEquipment) {
    if (requiredEquipment.isEmpty) return true;
    
    // Для зала проверяем только критически важное оборудование
    if (recommendedLocation == TrainingLocation.gym) {
      final criticalEquipment = requiredEquipment
          .where((eq) => ![Equipment.cardioEquipment, Equipment.cableMachine].contains(eq))
          .toList();
      return criticalEquipment.every((req) => availableEquipment.contains(req));
    }
    
    return requiredEquipment.every((req) => availableEquipment.contains(req));
  }

  // Адаптировать систему под пользователя
  TrainingSystemTemplate adaptToUser(UserPreferences prefs) {
    final adaptedStructure = Map<int, WorkoutDayTemplate>.from(weeklyStructure);
    
    // Адаптация количества дней
    if (prefs.daysPerWeek != null && prefs.daysPerWeek != recommendedDaysPerWeek) {
      adaptedStructure.clear();
      
      // Создаем упрощенную структуру для меньшего количества дней
      if (prefs.daysPerWeek! < recommendedDaysPerWeek) {
        for (int i = 1; i <= prefs.daysPerWeek!; i++) {
          adaptedStructure[i] = WorkoutDayTemplate(
            dayNumber: i,
            focus: 'Full Body',
            exercises: [],
            isRestDay: false,
          );
        }
      }
    }

    return copyWith(weeklyStructure: adaptedStructure);
  }

  // Получить рекомендации по системе
  Map<String, dynamic> getRecommendations() {
    return {
      'system': name,
      'description': description,
      'targetAudience': targetAudience,
      'daysPerWeek': recommendedDaysPerWeek,
      'sessionDuration': recommendedSessionDuration,
      'equipment': requiredEquipment.map((e) => e.displayName).toList(),
      'progressionTips': _getProgressionTips(),
      'recoveryTips': _getRecoveryTips(),
    };
  }

  String _getProgressionTips() {
    switch (system) {
      case TrainingSystem.fullBody:
        return 'Увеличивайте вес каждую неделю на 2.5-5%';
      case TrainingSystem.split:
        return 'Фокусируйтесь на технике, добавляйте вес раз в 2 недели';
      case TrainingSystem.ppl:
        return 'Прогрессируйте в основных упражнениях каждую тренировку';
      case TrainingSystem.upperLower:
        return 'Чередуйте тяжелые и легкие дни для каждой группы';
      case TrainingSystem.circuit:
        return 'Уменьшайте время отдыха или увеличивайте количество кругов';
      case TrainingSystem.cardio:
        return 'Увеличивайте продолжительность или интенсивность на 10% в неделю';
    }
  }

  String _getRecoveryTips() {
    switch (system) {
      case TrainingSystem.fullBody:
        return 'Отдых 48 часов между тренировками, фокус на сне и питании';
      case TrainingSystem.split:
        return 'Каждая группа мышц отдыхает 72 часа перед следующей тренировкой';
      case TrainingSystem.ppl:
        return 'Отдых 24-48 часов между тренировками одной группы';
      case TrainingSystem.upperLower:
        return 'Чередуйте верх и низ, давая каждой части 48-72 часа отдыха';
      case TrainingSystem.circuit:
        return 'Восстановление важно - отдых 24 часа между высокоинтенсивными тренировками';
      case TrainingSystem.cardio:
        return 'Легкие дни для активного восстановления, 1-2 полных дня отдыха в неделю';
    }
  }

  TrainingSystemTemplate copyWith({
    TrainingSystem? system,
    String? name,
    String? description,
    String? targetAudience,
    UserGoal? primaryGoal,
    List<UserGoal>? compatibleGoals,
    ExperienceLevel? minExperienceLevel,
    List<ExperienceLevel>? compatibleLevels,
    BodyType? recommendedBodyType,
    int? recommendedDaysPerWeek,
    int? recommendedSessionDuration,
    TrainingLocation? recommendedLocation,
    List<Equipment>? requiredEquipment,
    Map<int, WorkoutDayTemplate>? weeklyStructure,
    Map<String, dynamic>? progressionRules,
    Map<String, dynamic>? adaptationRules,
    int? priority,
  }) {
    return TrainingSystemTemplate(
      system: system ?? this.system,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAudience: targetAudience ?? this.targetAudience,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      compatibleGoals: compatibleGoals ?? this.compatibleGoals,
      minExperienceLevel: minExperienceLevel ?? this.minExperienceLevel,
      compatibleLevels: compatibleLevels ?? this.compatibleLevels,
      recommendedBodyType: recommendedBodyType ?? this.recommendedBodyType,
      recommendedDaysPerWeek: recommendedDaysPerWeek ?? this.recommendedDaysPerWeek,
      recommendedSessionDuration: recommendedSessionDuration ?? this.recommendedSessionDuration,
      recommendedLocation: recommendedLocation ?? this.recommendedLocation,
      requiredEquipment: requiredEquipment ?? this.requiredEquipment,
      weeklyStructure: weeklyStructure ?? this.weeklyStructure,
      progressionRules: progressionRules ?? this.progressionRules,
      adaptationRules: adaptationRules ?? this.adaptationRules,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'system': system.name,
      'name': name,
      'description': description,
      'targetAudience': targetAudience,
      'primaryGoal': primaryGoal.name,
      'compatibleGoals': compatibleGoals.map((g) => g.name).toList(),
      'minExperienceLevel': minExperienceLevel.name,
      'compatibleLevels': compatibleLevels.map((l) => l.name).toList(),
      'recommendedBodyType': recommendedBodyType?.name,
      'recommendedDaysPerWeek': recommendedDaysPerWeek,
      'recommendedSessionDuration': recommendedSessionDuration,
      'recommendedLocation': recommendedLocation.name,
      'requiredEquipment': requiredEquipment.map((e) => e.name).toList(),
      'weeklyStructure': weeklyStructure.map((key, value) => 
          MapEntry(key.toString(), value.toJson())),
      'progressionRules': progressionRules,
      'adaptationRules': adaptationRules,
      'priority': priority,
    };
  }

  factory TrainingSystemTemplate.fromJson(Map<String, dynamic> json) {
    return TrainingSystemTemplate(
      system: TrainingSystem.values.byName(json['system']),
      name: json['name'] as String,
      description: json['description'] as String,
      targetAudience: json['targetAudience'] as String,
      primaryGoal: UserGoal.values.byName(json['primaryGoal']),
      compatibleGoals: (json['compatibleGoals'] as List<dynamic>?)
          ?.map((g) => UserGoal.values.byName(g as String))
          .toList() ?? [],
      minExperienceLevel: ExperienceLevel.values.byName(json['minExperienceLevel']),
      compatibleLevels: (json['compatibleLevels'] as List<dynamic>?)
          ?.map((l) => ExperienceLevel.values.byName(l as String))
          .toList() ?? [],
      recommendedBodyType: json['recommendedBodyType'] != null
          ? BodyType.values.byName(json['recommendedBodyType'] as String)
          : null,
      recommendedDaysPerWeek: json['recommendedDaysPerWeek'] as int,
      recommendedSessionDuration: json['recommendedSessionDuration'] as int,
      recommendedLocation: TrainingLocation.values.byName(json['recommendedLocation']),
      requiredEquipment: (json['requiredEquipment'] as List<dynamic>?)
          ?.map((e) => Equipment.values.byName(e as String))
          .toList() ?? [],
      weeklyStructure: (json['weeklyStructure'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          int.parse(key),
          WorkoutDayTemplate.fromJson(value as Map<String, dynamic>),
        ),
      ),
      progressionRules: Map<String, dynamic>.from(json['progressionRules'] as Map),
      adaptationRules: Map<String, dynamic>.from(json['adaptationRules'] as Map),
      priority: json['priority'] as int? ?? 5,
    );
  }
}

// Шаблон тренировочного дня
class WorkoutDayTemplate {
  final int dayNumber;
  final String focus; // фокус дня: "Chest & Triceps", "Legs", "Full Body", etc.
  final List<ExerciseTemplate> exercises;
  final bool isRestDay;
  final String? notes;

  const WorkoutDayTemplate({
    required this.dayNumber,
    required this.focus,
    required this.exercises,
    this.isRestDay = false,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'focus': focus,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'isRestDay': isRestDay,
      'notes': notes,
    };
  }

  factory WorkoutDayTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutDayTemplate(
      dayNumber: json['dayNumber'] as int,
      focus: json['focus'] as String,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => ExerciseTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
      isRestDay: json['isRestDay'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  WorkoutDayTemplate copyWith({
    int? dayNumber,
    String? focus,
    List<ExerciseTemplate>? exercises,
    bool? isRestDay,
    String? notes,
  }) {
    return WorkoutDayTemplate(
      dayNumber: dayNumber ?? this.dayNumber,
      focus: focus ?? this.focus,
      exercises: exercises ?? this.exercises,
      isRestDay: isRestDay ?? this.isRestDay,
      notes: notes ?? this.notes,
    );
  }
}

// Шаблон упражнения в системе
class ExerciseTemplate {
  final String exerciseId;
  final int sets;
  final int reps;
  final int restTime; // в секундах
  final bool isSuperSet;
  final String? tempo; // темп выполнения, например "2-1-2"
  final double? rpe; // уровень воспринимаемого напряжения (1-10)
  final String? notes;

  const ExerciseTemplate({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.restTime = 60,
    this.isSuperSet = false,
    this.tempo,
    this.rpe,
    this.notes,
  });

  // Адаптировать под уровень пользователя
  ExerciseTemplate adaptToLevel(ExperienceLevel level) {
    int adaptedSets = sets;
    int adaptedReps = reps;
    int adaptedRestTime = restTime;

    switch (level) {
      case ExperienceLevel.beginner:
        adaptedSets = sets.clamp(2, 3);
        adaptedReps = reps.clamp(8, 12);
        adaptedRestTime = restTime.clamp(60, 90);
        break;
      case ExperienceLevel.intermediate:
        adaptedSets = sets.clamp(3, 4);
        adaptedReps = reps.clamp(6, 10);
        adaptedRestTime = restTime.clamp(90, 120);
        break;
      case ExperienceLevel.advanced:
        adaptedSets = sets.clamp(4, 5);
        adaptedReps = reps.clamp(4, 8);
        adaptedRestTime = restTime.clamp(120, 180);
        break;
    }

    return copyWith(
      sets: adaptedSets,
      reps: adaptedReps,
      restTime: adaptedRestTime,
    );
  }

  ExerciseTemplate copyWith({
    String? exerciseId,
    int? sets,
    int? reps,
    int? restTime,
    bool? isSuperSet,
    String? tempo,
    double? rpe,
    String? notes,
  }) {
    return ExerciseTemplate(
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restTime: restTime ?? this.restTime,
      isSuperSet: isSuperSet ?? this.isSuperSet,
      tempo: tempo ?? this.tempo,
      rpe: rpe ?? this.rpe,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'sets': sets,
      'reps': reps,
      'restTime': restTime,
      'isSuperSet': isSuperSet,
      'tempo': tempo,
      'rpe': rpe,
      'notes': notes,
    };
  }

  factory ExerciseTemplate.fromJson(Map<String, dynamic> json) {
    return ExerciseTemplate(
      exerciseId: json['exerciseId'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      restTime: json['restTime'] as int? ?? 60,
      isSuperSet: json['isSuperSet'] as bool? ?? false,
      tempo: json['tempo'] as String?,
      rpe: json['rpe']?.toDouble(),
      notes: json['notes'] as String?,
    );
  }
}