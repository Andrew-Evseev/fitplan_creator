class Exercise {
  final String id;
  final String name;
  final String description;
  final String instructions;
  final String primaryMuscleGroup;
  final List<String> secondaryMuscleGroups;
  final List<String> requiredEquipment;
  final String difficulty;
  final String? imageUrl;
  final String? videoUrl;

  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.instructions,
    required this.primaryMuscleGroup,
    this.secondaryMuscleGroups = const [],
    this.requiredEquipment = const [],
    this.difficulty = 'intermediate',
    this.imageUrl,
    this.videoUrl,
  });

  factory Exercise.empty() {
    return const Exercise(
      id: '',
      name: '',
      description: '',
      instructions: '',
      primaryMuscleGroup: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'instructions': instructions,
      'primaryMuscleGroup': primaryMuscleGroup,
      'secondaryMuscleGroups': secondaryMuscleGroups,
      'requiredEquipment': requiredEquipment,
      'difficulty': difficulty,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      instructions: json['instructions'] as String,
      primaryMuscleGroup: json['primaryMuscleGroup'] as String,
      secondaryMuscleGroups: (json['secondaryMuscleGroups'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      requiredEquipment: (json['requiredEquipment'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      difficulty: json['difficulty'] as String? ?? 'intermediate',
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
    );
  }
}