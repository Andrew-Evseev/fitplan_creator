// lib/data/models/user_preferences.dart
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

// НОВЫЕ ПЕРЕЧИСЛЕНИЯ
enum Gender {
  male('Мужской'),
  female('Женский'),
  other('Другой');

  const Gender(this.displayName);
  final String displayName;
}

enum BodyType {
  ectomorph('Эктоморф (худощавый)'),
  mesomorph('Мезоморф (спортивный)'),
  endomorph('Эндоморф (крупный)');

  const BodyType(this.displayName);
  final String displayName;
}

enum ActivityLevel {
  sedentary('Сидячий образ жизни', 1.2),
  light('Легкая активность', 1.375),
  moderate('Умеренная активность', 1.55),
  active('Высокая активность', 1.725),
  veryActive('Очень высокая активность', 1.9);

  const ActivityLevel(this.displayName, this.multiplier);
  final String displayName;
  final double multiplier;
}

enum HealthRestriction {
  back('Проблемы со спиной'),
  knees('Проблемы с коленями'),
  shoulders('Проблемы с плечами'),
  neck('Проблемы с шеей'),
  wrist('Проблемы с запястьями'),
  elbow('Проблемы с локтями'),
  hip('Проблемы с тазобедренными суставами'),
  none('Нет ограничений');

  const HealthRestriction(this.displayName);
  final String displayName;
}

class UserPreferences {
  // СУЩЕСТВУЮЩИЕ ПОЛЯ
  final UserGoal? goal;
  final ExperienceLevel? experienceLevel;
  final List<Equipment> availableEquipment;
  final int? daysPerWeek;
  final int? sessionDuration;
  
  // НОВЫЕ ПОЛЯ
  final Gender? gender;
  final int? age;
  final double? height; // в см
  final double? weight; // в кг
  final double? targetWeight; // в кг
  final ActivityLevel? activityLevel;
  final BodyType? bodyType;
  final List<HealthRestriction> healthRestrictions;
  final List<String> favoriteMuscleGroups;
  final List<String> dislikedExercises;

  const UserPreferences({
    // Старые поля
    this.goal,
    this.experienceLevel,
    this.availableEquipment = const [],
    this.daysPerWeek,
    this.sessionDuration,
    
    // Новые поля
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.targetWeight,
    this.activityLevel,
    this.bodyType,
    this.healthRestrictions = const [],
    this.favoriteMuscleGroups = const [],
    this.dislikedExercises = const [],
  });

  UserPreferences copyWith({
    // Старые поля
    UserGoal? goal,
    ExperienceLevel? experienceLevel,
    List<Equipment>? availableEquipment,
    int? daysPerWeek,
    int? sessionDuration,
    
    // Новые поля
    Gender? gender,
    int? age,
    double? height,
    double? weight,
    double? targetWeight,
    ActivityLevel? activityLevel,
    BodyType? bodyType,
    List<HealthRestriction>? healthRestrictions,
    List<String>? favoriteMuscleGroups,
    List<String>? dislikedExercises,
  }) {
    return UserPreferences(
      goal: goal ?? this.goal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      targetWeight: targetWeight ?? this.targetWeight,
      activityLevel: activityLevel ?? this.activityLevel,
      bodyType: bodyType ?? this.bodyType,
      healthRestrictions: healthRestrictions ?? this.healthRestrictions,
      favoriteMuscleGroups: favoriteMuscleGroups ?? this.favoriteMuscleGroups,
      dislikedExercises: dislikedExercises ?? this.dislikedExercises,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Старые поля
      'goal': goal?.name,
      'experienceLevel': experienceLevel?.name,
      'availableEquipment': availableEquipment.map((e) => e.name).toList(),
      'daysPerWeek': daysPerWeek,
      'sessionDuration': sessionDuration,
      
      // Новые поля
      'gender': gender?.name,
      'age': age,
      'height': height,
      'weight': weight,
      'targetWeight': targetWeight,
      'activityLevel': activityLevel?.name,
      'bodyType': bodyType?.name,
      'healthRestrictions': healthRestrictions.map((e) => e.name).toList(),
      'favoriteMuscleGroups': favoriteMuscleGroups,
      'dislikedExercises': dislikedExercises,
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
      
      // Новые поля
      gender: json['gender'] != null ? Gender.values.byName(json['gender']) : null,
      age: json['age'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      targetWeight: json['targetWeight']?.toDouble(),
      activityLevel: json['activityLevel'] != null 
          ? ActivityLevel.values.byName(json['activityLevel']) 
          : null,
      bodyType: json['bodyType'] != null 
          ? BodyType.values.byName(json['bodyType']) 
          : null,
      healthRestrictions: json['healthRestrictions'] != null
          ? (json['healthRestrictions'] as List)
              .map((e) => HealthRestriction.values.byName(e))
              .toList()
          : [],
      favoriteMuscleGroups: json['favoriteMuscleGroups'] != null
          ? List<String>.from(json['favoriteMuscleGroups'])
          : [],
      dislikedExercises: json['dislikedExercises'] != null
          ? List<String>.from(json['dislikedExercises'])
          : [],
    );
  }

  bool get isComplete {
    return goal != null &&
        experienceLevel != null &&
        availableEquipment.isNotEmpty &&
        daysPerWeek != null &&
        sessionDuration != null &&
        gender != null &&
        age != null &&
        height != null &&
        weight != null &&
        activityLevel != null;
  }
  
  double? get bmi {
    if (height == null || weight == null || height! <= 0) return null;
    return weight! / ((height! / 100) * (height! / 100));
  }
  
  double? get bmr {
    if (weight == null || height == null || age == null || gender == null) {
      return null;
    }
    
    if (gender == Gender.male) {
      return 88.362 + (13.397 * weight!) + (4.799 * height!) - (5.677 * age!);
    } else {
      return 447.593 + (9.247 * weight!) + (3.098 * height!) - (4.330 * age!);
    }
  }
  
  double? get dailyCalories {
    final bmrValue = bmr;
    final activityMultiplier = activityLevel?.multiplier;
    
    if (bmrValue == null || activityMultiplier == null) return null;
    
    return bmrValue * activityMultiplier;
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Не определен';
    
    if (bmiValue < 18.5) return 'Недостаточный вес';
    if (bmiValue < 25) return 'Нормальный вес';
    if (bmiValue < 30) return 'Избыточный вес';
    return 'Ожирение';
  }

  int get recommendedDailyProtein {
    if (weight == null) return 0;
    
    // Рекомендация: 1.6-2.2 г белка на кг веса для силовых тренировок
    final proteinPerKg = goal == UserGoal.muscleGain || goal == UserGoal.strength ? 2.0 : 1.6;
    return (weight! * proteinPerKg).round();
  }

  int get recommendedDailyWater {
    if (weight == null) return 0;
    // 30-40 мл на кг веса
    return (weight! * 35).round();
  }
}