class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final List<String> equipment;
  final String difficulty;
  final String gifUrl;
  final List<String> substituteIds;
  final String description;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.difficulty,
    required this.gifUrl,
    required this.substituteIds,
    required this.description,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      muscleGroup: map['muscleGroup'] ?? '',
      equipment: List<String>.from(map['equipment'] ?? []),
      difficulty: map['difficulty'] ?? 'beginner',
      gifUrl: map['gifUrl'] ?? '',
      substituteIds: List<String>.from(map['substituteIds'] ?? []),
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'muscleGroup': muscleGroup,
      'equipment': equipment,
      'difficulty': difficulty,
      'gifUrl': gifUrl,
      'substituteIds': substituteIds,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, muscleGroup: $muscleGroup)';
  }
}