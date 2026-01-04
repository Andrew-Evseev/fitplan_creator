enum MuscleGroup {
  chest('Грудь'),
  back('Спина'),
  shoulders('Плечи'),
  biceps('Бицепс'),
  triceps('Трицепс'),
  quadriceps('Квадрицепс'),
  hamstrings('Бицепс бедра'),
  glutes('Ягодицы'),
  calves('Икры'),
  core('Пресс'),
  fullBody('Все тело'),
  forearms('Предплечья'),
  traps('Трапеции');

  const MuscleGroup(this.displayName);
  final String displayName;

  static MuscleGroup fromString(String value) {
    return values.firstWhere(
      (e) => e.name == value.toLowerCase().replaceAll(' ', ''),
      orElse: () => MuscleGroup.fullBody,
    );
  }
}