enum UserGoal {
  weightLoss('Похудение'),
  muscleGain('Набор мышечной массы'),
  endurance('Развитие выносливости'),
  strength('Увеличение силы'),
  generalFitness('Общая физическая форма');

  const UserGoal(this.displayName);
  final String displayName;
}

enum ExperienceLevel {
  beginner('Новичок', 'Менее 6 месяцев'),
  intermediate('Средний', '6 месяцев - 2 года'),
  advanced('Опытный', 'Более 2 лет');

  const ExperienceLevel(this.displayName, this.description);
  final String displayName;
  final String description;
}

enum Equipment {
  dumbbells('Гантели'),
  barbell('Штанга'),
  resistanceBands('Эспандеры'),
  pullUpBar('Турник'),
  bench('Скамья'),
  kettlebell('Гиря'),
  none('Без оборудования');

  const Equipment(this.displayName);
  final String displayName;
}

class UserPreferences {
  final UserGoal? goal;
  final ExperienceLevel? experienceLevel;
  final List<Equipment> availableEquipment;
  final int? daysPerWeek;
  final int? sessionDuration; // в минутах

  UserPreferences({
    this.goal,
    this.experienceLevel,
    this.availableEquipment = const [],
    this.daysPerWeek,
    this.sessionDuration,
  });

  UserPreferences copyWith({
    UserGoal? goal,
    ExperienceLevel? experienceLevel,
    List<Equipment>? availableEquipment,
    int? daysPerWeek,
    int? sessionDuration,
  }) {
    return UserPreferences(
      goal: goal ?? this.goal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      sessionDuration: sessionDuration ?? this.sessionDuration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal': goal?.name,
      'experienceLevel': experienceLevel?.name,
      'availableEquipment': availableEquipment.map((e) => e.name).toList(),
      'daysPerWeek': daysPerWeek,
      'sessionDuration': sessionDuration,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      goal: json['goal'] != null ? UserGoal.values.byName(json['goal']) : null,
      experienceLevel: json['experienceLevel'] != null
          ? ExperienceLevel.values.byName(json['experienceLevel'])
          : null,
      availableEquipment: json['availableEquipment'] != null
          ? (json['availableEquipment'] as List)
              .map((e) => Equipment.values.byName(e))
              .toList()
          : [],
      daysPerWeek: json['daysPerWeek'],
      sessionDuration: json['sessionDuration'],
    );
  }

  bool get isComplete {
    return goal != null &&
        experienceLevel != null &&
        availableEquipment.isNotEmpty &&
        daysPerWeek != null &&
        sessionDuration != null;
  }
}