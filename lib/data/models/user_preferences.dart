class UserPreferences {
  final String goal;
  final String level;
  final List<String> equipment;

  const UserPreferences({
    required this.goal,
    required this.level,
    required this.equipment,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      goal: map['goal'] ?? '',
      level: map['level'] ?? '',
      equipment: List<String>.from(map['equipment'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'goal': goal,
      'level': level,
      'equipment': equipment,
    };
  }

  @override
  String toString() {
    return 'UserPreferences(goal: $goal, level: $level, equipment: $equipment)';
  }
}