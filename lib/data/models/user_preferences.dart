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

// ==================== НОВАЯ СТРУКТУРА ОБОРУДОВАНИЯ ====================
enum TrainingLocation {
  gym('🏋️ Тренажёрный зал'),
  home('🏠 Домашние тренировки'),
  street('🌳 Уличная площадка'),
  bodyweight('💪 Только с весом тела');

  const TrainingLocation(this.displayName);
  final String displayName;
}

enum Equipment {
  // Базовое оборудование для зала
  barbell('Штанга'),
  dumbbells('Гантели'),
  bench('Скамья'),
  pullUpBar('Турник'),
  parallelBars('Брусья'),
  cableMachine('Тренажёр с блоками'),
  legPress('Тренажёр для жима ногами'),
  smithMachine('Тренажёр Смита'),
  cardioEquipment('Кардио-оборудование'),
  
  // Домашнее оборудование
  resistanceBands('Эспандеры'),
  kettlebell('Гиря'),
  exerciseBall('Фитбол'),
  jumpRope('Скакалка'),
  yogaMat('Коврик для йоги'),
  abRoller('Ролик для пресса'),
  suspensionTrainer('Петли TRX'),
  
  // Уличное оборудование
  highBar('Турник высокой перекладины'),
  lowBar('Турник низкой перекладины'),
  monkeyBars('Рукоход'),
  swedishWall('Шведская стенка'),
  dipBars('Брусья для отжиманий'),
  
  // Общие
  bodyweight('Без оборудования'),
  none('Нет оборудования');

  const Equipment(this.displayName);
  final String displayName;
}

// ==================== СИСТЕМЫ ТРЕНИРОВОК ====================
enum TrainingSystem {
  fullBody('Фулбади (Full Body)', 'Развитие общей силы и мышечной массы', 'Начинающие, средний уровень'),
  split('Сплит (Split)', 'Прицельный набор мышечной массы', 'Средний и опытный уровень'),
  ppl('PPL (Push-Pull-Legs)', 'Максимальный набор массы и силы', 'Средний и опытный уровень'),
  upperLower('Верх/Низ (Upper/Lower)', 'Сбалансированное развитие', 'Все уровни'),
  circuit('Круговая (Circuit)', 'Выносливость, жиросжигание', 'Все уровни'),
  cardio('Кардио тренировки', 'Укрепление сердца, жиросжигание', 'Все уровни');

  const TrainingSystem(this.displayName, this.description, this.audience);
  final String displayName;
  final String description;
  final String audience;
}

// ==================== ДОПОЛНИТЕЛЬНЫЕ ПЕРЕЧИСЛЕНИЯ ====================
enum Gender {
  male('Мужской'),
  female('Женский'),
  other('Другой');

  const Gender(this.displayName);
  final String displayName;
}

enum BodyType {
  ectomorph('Эктоморф', 'Худощавый, быстрый метаболизм'),
  mesomorph('Мезоморф', 'Атлетичный, мышечный'),
  endomorph('Эндоморф', 'Крупный, склонен к набору веса');

  const BodyType(this.displayName, this.description);
  final String displayName;
  final String description;
}

enum ActivityLevel {
  sedentary('Сидячий образ жизни', 1.2, 'Мало или нет физической активности'),
  light('Легкая активность', 1.375, 'Легкие упражнения 1-3 дня в неделю'),
  moderate('Умеренная активность', 1.55, 'Умеренные упражнения 3-5 дней в неделю'),
  active('Высокая активность', 1.725, 'Тяжелые упражнения 6-7 дней в неделю'),
  veryActive('Очень высокая активность', 1.9, 'Тяжелые упражнения + физическая работа');

  const ActivityLevel(this.displayName, this.multiplier, this.description);
  final String displayName;
  final double multiplier;
  final String description;
}

enum HealthRestriction {
  back('Проблемы со спиной'),
  knees('Проблемы с коленями'),
  shoulders('Проблемы с плечами'),
  neck('Проблемы с шеей'),
  wrist('Проблемы с запястьями'),
  elbow('Проблемы с локтями'),
  hip('Проблемы с тазобедренными суставами'),
  highBloodPressure('Высокое давление'),
  heartIssues('Проблемы с сердцем'),
  none('Нет ограничений');

  const HealthRestriction(this.displayName);
  final String displayName;
}

// ==================== МОДЕЛЬ ПОЛЬЗОВАТЕЛЬСКИХ ПРЕДПОЧТЕНИЙ ====================
class UserPreferences {
  // Базовые данные
  final Gender? gender;
  final int? age;
  final double? height; // в см
  final double? weight; // в кг
  final double? targetWeight; // в кг
  
  // Цели и активность
  final UserGoal? goal;
  final ActivityLevel? activityLevel;
  
  // Опыт и телосложение
  final ExperienceLevel? experienceLevel;
  final BodyType? bodyType;
  
  // Место тренировок и оборудование
  final TrainingLocation? trainingLocation;
  final List<Equipment> availableEquipment;
  
  // Ограничения по здоровью
  final List<HealthRestriction> healthRestrictions;
  
  // Предпочтения
  final List<String> favoriteMuscleGroups;
  final List<String> dislikedExercises;
  
  // График тренировок
  final int? daysPerWeek;
  final int? sessionDuration; // в минутах
  
  // Система тренировок (может быть выбрана пользователем или подобрана автоматически)
  final TrainingSystem? preferredSystem;
  
  // Дополнительные параметры
  final DateTime? createdAt;
  final bool hasPreviousExperience;
  final List<String> preferredExerciseTypes; // strength, cardio, flexibility, etc.

  const UserPreferences({
    // Базовые данные
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.targetWeight,
    
    // Цели и активность
    this.goal,
    this.activityLevel,
    
    // Опыт и телосложение
    this.experienceLevel,
    this.bodyType,
    
    // Место тренировок и оборудование
    this.trainingLocation,
    this.availableEquipment = const [],
    
    // Ограничения по здоровью
    this.healthRestrictions = const [],
    
    // Предпочтения
    this.favoriteMuscleGroups = const [],
    this.dislikedExercises = const [],
    
    // График тренировок
    this.daysPerWeek,
    this.sessionDuration,
    
    // Система тренировок
    this.preferredSystem,
    
    // Дополнительные параметры
    this.createdAt,
    this.hasPreviousExperience = false,
    this.preferredExerciseTypes = const [],
  });

  // Копирование с обновлением
  UserPreferences copyWith({
    Gender? gender,
    int? age,
    double? height,
    double? weight,
    double? targetWeight,
    UserGoal? goal,
    ActivityLevel? activityLevel,
    ExperienceLevel? experienceLevel,
    BodyType? bodyType,
    TrainingLocation? trainingLocation,
    List<Equipment>? availableEquipment,
    List<HealthRestriction>? healthRestrictions,
    List<String>? favoriteMuscleGroups,
    List<String>? dislikedExercises,
    int? daysPerWeek,
    int? sessionDuration,
    TrainingSystem? preferredSystem,
    DateTime? createdAt,
    bool? hasPreviousExperience,
    List<String>? preferredExerciseTypes,
  }) {
    return UserPreferences(
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      targetWeight: targetWeight ?? this.targetWeight,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      bodyType: bodyType ?? this.bodyType,
      trainingLocation: trainingLocation ?? this.trainingLocation,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      healthRestrictions: healthRestrictions ?? this.healthRestrictions,
      favoriteMuscleGroups: favoriteMuscleGroups ?? this.favoriteMuscleGroups,
      dislikedExercises: dislikedExercises ?? this.dislikedExercises,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      preferredSystem: preferredSystem ?? this.preferredSystem,
      createdAt: createdAt ?? this.createdAt,
      hasPreviousExperience: hasPreviousExperience ?? this.hasPreviousExperience,
      preferredExerciseTypes: preferredExerciseTypes ?? this.preferredExerciseTypes,
    );
  }

  // Сериализация
  Map<String, dynamic> toJson() {
    return {
      // Базовые данные
      'gender': gender?.name,
      'age': age,
      'height': height,
      'weight': weight,
      'targetWeight': targetWeight,
      
      // Цели и активность
      'goal': goal?.name,
      'activityLevel': activityLevel?.name,
      
      // Опыт и телосложение
      'experienceLevel': experienceLevel?.name,
      'bodyType': bodyType?.name,
      
      // Место тренировок и оборудование
      'trainingLocation': trainingLocation?.name,
      'availableEquipment': availableEquipment.map((e) => e.name).toList(),
      
      // Ограничения по здоровью
      'healthRestrictions': healthRestrictions.map((e) => e.name).toList(),
      
      // Предпочтения
      'favoriteMuscleGroups': favoriteMuscleGroups,
      'dislikedExercises': dislikedExercises,
      
      // График тренировок
      'daysPerWeek': daysPerWeek,
      'sessionDuration': sessionDuration,
      
      // Система тренировок
      'preferredSystem': preferredSystem?.name,
      
      // Дополнительные параметры
      'createdAt': createdAt?.toIso8601String(),
      'hasPreviousExperience': hasPreviousExperience,
      'preferredExerciseTypes': preferredExerciseTypes,
    };
  }

  // Десериализация
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      gender: json['gender'] != null ? Gender.values.byName(json['gender']) : null,
      age: json['age'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      targetWeight: json['targetWeight']?.toDouble(),
      goal: json['goal'] != null ? UserGoal.values.byName(json['goal']) : null,
      activityLevel: json['activityLevel'] != null 
          ? ActivityLevel.values.byName(json['activityLevel']) 
          : null,
      experienceLevel: json['experienceLevel'] != null
          ? ExperienceLevel.values.byName(json['experienceLevel'])
          : null,
      bodyType: json['bodyType'] != null 
          ? BodyType.values.byName(json['bodyType']) 
          : null,
      trainingLocation: json['trainingLocation'] != null
          ? TrainingLocation.values.byName(json['trainingLocation'])
          : null,
      availableEquipment: json['availableEquipment'] != null
          ? (json['availableEquipment'] as List)
              .map((e) => Equipment.values.byName(e))
              .toList()
          : [],
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
      daysPerWeek: json['daysPerWeek'],
      sessionDuration: json['sessionDuration'],
      preferredSystem: json['preferredSystem'] != null
          ? TrainingSystem.values.byName(json['preferredSystem'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      hasPreviousExperience: json['hasPreviousExperience'] as bool? ?? false,
      preferredExerciseTypes: json['preferredExerciseTypes'] != null
          ? List<String>.from(json['preferredExerciseTypes'])
          : [],
    );
  }

  // Проверка заполнения обязательных полей
  bool get isComplete {
    return gender != null &&
        age != null &&
        height != null &&
        weight != null &&
        goal != null &&
        activityLevel != null &&
        experienceLevel != null &&
        trainingLocation != null &&
        availableEquipment.isNotEmpty &&
        daysPerWeek != null &&
        sessionDuration != null;
  }
  
  // Расчетные свойства
  
  // Индекс массы тела
  double? get bmi {
    if (height == null || weight == null || height! <= 0) return null;
    return weight! / ((height! / 100) * (height! / 100));
  }
  
  // Базовый метаболизм (BMR) по формуле Миффлина-Сан Жеора
  double? get bmr {
    if (weight == null || height == null || age == null || gender == null) {
      return null;
    }
    
    if (gender == Gender.male) {
      return 10 * weight! + 6.25 * height! - 5 * age! + 5;
    } else {
      return 10 * weight! + 6.25 * height! - 5 * age! - 161;
    }
  }
  
  // Суточная потребность в калориях
  double? get dailyCalories {
    final bmrValue = bmr;
    final activityMultiplier = activityLevel?.multiplier;
    
    if (bmrValue == null || activityMultiplier == null) return null;
    
    return bmrValue * activityMultiplier;
  }

  // Категория ИМТ
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Не определен';
    
    if (bmiValue < 18.5) return 'Недостаточный вес';
    if (bmiValue < 25) return 'Нормальный вес';
    if (bmiValue < 30) return 'Избыточный вес';
    return 'Ожирение';
  }

  // Рекомендуемое количество белка в день (г)
  int get recommendedDailyProtein {
    if (weight == null) return 0;
    
    // Рекомендация: 1.6-2.2 г белка на кг веса для силовых тренировок
    final proteinPerKg = goal == UserGoal.muscleGain || goal == UserGoal.strength ? 2.2 : 1.6;
    return (weight! * proteinPerKg).round();
  }

  // Рекомендуемое количество воды в день (мл)
  int get recommendedDailyWater {
    if (weight == null) return 0;
    // 30-40 мл на кг веса
    return (weight! * 35).round();
  }

  // Получить рекомендуемую систему тренировок на основе профиля
  TrainingSystem get recommendedSystem {
    if (preferredSystem != null) return preferredSystem!;
    
    // Алгоритм выбора системы
    if (experienceLevel == ExperienceLevel.beginner) {
      if (goal == UserGoal.weightLoss) {
        return TrainingSystem.circuit;
      } else if (trainingLocation == TrainingLocation.home) {
        return TrainingSystem.fullBody;
      } else {
        return TrainingSystem.upperLower;
      }
    } else if (experienceLevel == ExperienceLevel.intermediate) {
      if (goal == UserGoal.muscleGain) {
        return daysPerWeek! >= 4 ? TrainingSystem.ppl : TrainingSystem.split;
      } else if (goal == UserGoal.weightLoss) {
        return TrainingSystem.circuit;
      } else {
        return TrainingSystem.upperLower;
      }
    } else { // advanced
      if (goal == UserGoal.muscleGain || goal == UserGoal.strength) {
        return daysPerWeek! >= 5 ? TrainingSystem.ppl : TrainingSystem.split;
      } else if (goal == UserGoal.weightLoss) {
        return TrainingSystem.upperLower;
      } else {
        return TrainingSystem.split;
      }
    }
  }

  // Получить оборудование по типу тренировочного пространства
  static List<Equipment> getEquipmentByLocation(TrainingLocation location) {
    switch (location) {
      case TrainingLocation.gym:
        return [
          Equipment.barbell,
          Equipment.dumbbells,
          Equipment.bench,
          Equipment.pullUpBar,
          Equipment.parallelBars,
          Equipment.cableMachine,
          Equipment.legPress,
          Equipment.smithMachine,
          Equipment.cardioEquipment,
        ];
      case TrainingLocation.home:
        return [
          Equipment.dumbbells,
          Equipment.resistanceBands,
          Equipment.kettlebell,
          Equipment.exerciseBall,
          Equipment.jumpRope,
          Equipment.yogaMat,
          Equipment.abRoller,
          Equipment.suspensionTrainer,
          Equipment.bodyweight,
        ];
      case TrainingLocation.street:
        return [
          Equipment.highBar,
          Equipment.lowBar,
          Equipment.monkeyBars,
          Equipment.swedishWall,
          Equipment.dipBars,
          Equipment.bodyweight,
        ];
      case TrainingLocation.bodyweight:
        return [Equipment.bodyweight];
    }
  }

  // Получить рекомендации по тренировкам на основе профиля
  Map<String, dynamic> get recommendations {
    return {
      'system': recommendedSystem.displayName,
      'frequency': '$daysPerWeek дней в неделю',
      'duration': '$sessionDuration минут на тренировку',
      'focus': _getTrainingFocus(),
      'priority': _getTrainingPriority(),
      'restDays': _getRecommendedRestDays(),
      'progression': _getProgressionRate(),
    };
  }

  String _getTrainingFocus() {
    switch (goal) {
      case UserGoal.weightLoss:
        return 'Высокая интенсивность, круговые тренировки, кардио';
      case UserGoal.muscleGain:
        return 'Силовые упражнения, прогрессия нагрузок, базовые движения';
      case UserGoal.endurance:
        return 'Выносливость, интервальные тренировки, большой объем';
      case UserGoal.strength:
        return 'Тяжелые веса, мало повторений, длительный отдых';
      case UserGoal.generalFitness:
        return 'Сбалансированный подход, всестороннее развитие';
      default:
        return 'Общая физическая подготовка';
    }
  }

  String _getTrainingPriority() {
    if (favoriteMuscleGroups.isNotEmpty) {
      return 'Акцент на: ${favoriteMuscleGroups.join(', ')}';
    }
    
    switch (bodyType) {
      case BodyType.ectomorph:
        return 'Акцент на базовые упражнения, питание, минимум кардио';
      case BodyType.mesomorph:
        return 'Сбалансированный подход, можно экспериментировать';
      case BodyType.endomorph:
        return 'Больше кардио, высокая частота тренировок, контроль питания';
      default:
        return 'Сбалансированное развитие всех групп мышц';
    }
  }

  int _getRecommendedRestDays() {
    if (daysPerWeek == null) return 2;
    
    if (daysPerWeek! <= 3) return 1;
    if (daysPerWeek! <= 5) return 2;
    return 1; // При 6-7 тренировках в неделю нужны активные восстановительные дни
  }

  String _getProgressionRate() {
    switch (experienceLevel) {
      case ExperienceLevel.beginner:
        return 'Быстрая (улучшения каждую неделю)';
      case ExperienceLevel.intermediate:
        return 'Умеренная (улучшения каждые 2-3 недели)';
      case ExperienceLevel.advanced:
        return 'Медленная (улучшения каждые 4-6 недель)';
      default:
        return 'Индивидуальная';
    }
  }

  @override
  String toString() {
    return 'UserPreferences('
        'gender: $gender, '
        'age: $age, '
        'goal: $goal, '
        'experience: $experienceLevel, '
        'location: $trainingLocation, '
        'system: $preferredSystem'
        ')';
  }
}