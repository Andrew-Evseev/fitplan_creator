enum ExerciseDifficulty {
  beginner,
  intermediate,
  advanced,
}

enum ExerciseCategory {
  warmup,
  chest,
  back,
  legs,
  shoulders,
  arms,
  abs,
  cardio,
  functional,
  cooldown,
  fullBody,
}

class Exercise {
  final String id;
  final String name;
  final String description;
  final String instructions;
  final List<ExerciseCategory> categories;
  final List<String> primaryMuscleGroups;
  final List<String> secondaryMuscleGroups;
  final List<String> requiredEquipment;
  final ExerciseDifficulty difficulty;
  final List<String> contraindications;
  final String? imageUrl;
  final String? videoUrl;
  final bool isBodyweight;
  final bool isWarmup;
  final bool isCooldown;
  final int estimatedCaloriesPerMinute;
  final int defaultSets;
  final int defaultReps;
  final int restTimeSeconds;

  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.instructions,
    required this.categories,
    required this.primaryMuscleGroups,
    this.secondaryMuscleGroups = const [],
    this.requiredEquipment = const [],
    required this.difficulty,
    this.contraindications = const [],
    this.imageUrl,
    this.videoUrl,
    this.isBodyweight = false,
    this.isWarmup = false,
    this.isCooldown = false,
    this.estimatedCaloriesPerMinute = 0,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.restTimeSeconds = 60,
  });

  factory Exercise.empty() {
    return Exercise(
      id: '',
      name: '',
      description: '',
      instructions: '',
      categories: [],
      primaryMuscleGroups: [],
      difficulty: ExerciseDifficulty.beginner,
    );
  }

  // Для удобства создаем геттеры
  bool get isCardio => categories.contains(ExerciseCategory.cardio);
  bool get isForBeginners => difficulty == ExerciseDifficulty.beginner;
  
  // Метод для проверки доступности упражнения при ограничениях здоровья
  bool isSafeFor(List<String> healthRestrictions) {
    if (contraindications.isEmpty) return true;
    return !contraindications.any((contra) => healthRestrictions.contains(contra));
  }

  // Метод для проверки доступности по оборудованию
  bool isAvailableWith(List<String> availableEquipment) {
    if (requiredEquipment.isEmpty || isBodyweight) return true;
    return requiredEquipment.every((equipment) => availableEquipment.contains(equipment));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'instructions': instructions,
      'categories': categories.map((e) => e.name).toList(),
      'primaryMuscleGroups': primaryMuscleGroups,
      'secondaryMuscleGroups': secondaryMuscleGroups,
      'requiredEquipment': requiredEquipment,
      'difficulty': difficulty.name,
      'contraindications': contraindications,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'isBodyweight': isBodyweight,
      'isWarmup': isWarmup,
      'isCooldown': isCooldown,
      'estimatedCaloriesPerMinute': estimatedCaloriesPerMinute,
      'defaultSets': defaultSets,
      'defaultReps': defaultReps,
      'restTimeSeconds': restTimeSeconds,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      instructions: json['instructions'] as String,
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) {
            final categoryName = e as String;
            return ExerciseCategory.values.firstWhere(
              (category) => category.name == categoryName,
              orElse: () => ExerciseCategory.fullBody,
            );
          })
          .toList() ?? [],
      primaryMuscleGroups: (json['primaryMuscleGroups'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      secondaryMuscleGroups: (json['secondaryMuscleGroups'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      requiredEquipment: (json['requiredEquipment'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      difficulty: ExerciseDifficulty.values.firstWhere(
        (d) => d.name == (json['difficulty'] as String? ?? 'beginner'),
        orElse: () => ExerciseDifficulty.beginner,
      ),
      contraindications: (json['contraindications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      isBodyweight: json['isBodyweight'] as bool? ?? false,
      isWarmup: json['isWarmup'] as bool? ?? false,
      isCooldown: json['isCooldown'] as bool? ?? false,
      estimatedCaloriesPerMinute: json['estimatedCaloriesPerMinute'] as int? ?? 0,
      defaultSets: json['defaultSets'] as int? ?? 3,
      defaultReps: json['defaultReps'] as int? ?? 10,
      restTimeSeconds: json['restTimeSeconds'] as int? ?? 60,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Вспомогательные функции для работы с упражнениями
extension ExerciseFilters on List<Exercise> {
  List<Exercise> filterByCategory(ExerciseCategory category) {
    return where((exercise) => exercise.categories.contains(category)).toList();
  }

  List<Exercise> filterByDifficulty(ExerciseDifficulty difficulty) {
    return where((exercise) => exercise.difficulty == difficulty).toList();
  }

  List<Exercise> filterByEquipment(List<String> availableEquipment) {
    return where((exercise) => exercise.isAvailableWith(availableEquipment)).toList();
  }

  List<Exercise> filterByHealthRestrictions(List<String> restrictions) {
    return where((exercise) => exercise.isSafeFor(restrictions)).toList();
  }

  List<Exercise> get bodyweightOnly {
    return where((exercise) => exercise.isBodyweight).toList();
  }

  List<Exercise> get forWarmup {
    return where((exercise) => exercise.isWarmup).toList();
  }

  List<Exercise> get forCooldown {
    return where((exercise) => exercise.isCooldown).toList();
  }
}