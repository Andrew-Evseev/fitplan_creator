// lib/features/questionnaire/providers/questionnaire_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';

class QuestionnaireNotifier extends StateNotifier<UserPreferences> {
  QuestionnaireNotifier() : super(const UserPreferences());

  void setGoal(UserGoal goal) {
    state = state.copyWith(goal: goal);
  }

  void setExperienceLevel(ExperienceLevel level) {
    state = state.copyWith(experienceLevel: level);
  }

  void toggleEquipment(Equipment equipment) {
    final List<Equipment> newEquipment;
    if (state.availableEquipment.contains(equipment)) {
      newEquipment = List.from(state.availableEquipment)..remove(equipment);
    } else {
      if (equipment == Equipment.none) {
        newEquipment = [equipment];
      } else {
        newEquipment = List.from(state.availableEquipment)
          ..remove(Equipment.none)
          ..add(equipment);
      }
    }
    state = state.copyWith(availableEquipment: newEquipment);
  }

  void setDaysPerWeek(int days) {
    state = state.copyWith(daysPerWeek: days);
  }

  void setSessionDuration(int minutes) {
    state = state.copyWith(sessionDuration: minutes);
  }

  // НОВЫЕ МЕТОДЫ ДЛЯ РАСШИРЕННОЙ АНКЕТЫ
  void setGender(Gender gender) {
    state = state.copyWith(gender: gender);
  }

  void setAge(int age) {
    state = state.copyWith(age: age);
  }

  void setHeight(double height) {
    state = state.copyWith(height: height);
  }

  void setWeight(double weight) {
    state = state.copyWith(weight: weight);
  }

  void setTargetWeight(double targetWeight) {
    state = state.copyWith(targetWeight: targetWeight);
  }

  void setActivityLevel(ActivityLevel level) {
    state = state.copyWith(activityLevel: level);
  }

  void setBodyType(BodyType bodyType) {
    state = state.copyWith(bodyType: bodyType);
  }

  void toggleHealthRestriction(HealthRestriction restriction) {
    final List<HealthRestriction> newRestrictions;
    if (state.healthRestrictions.contains(restriction)) {
      newRestrictions = List.from(state.healthRestrictions)..remove(restriction);
    } else {
      if (restriction == HealthRestriction.none) {
        newRestrictions = [restriction];
      } else {
        newRestrictions = List.from(state.healthRestrictions)
          ..remove(HealthRestriction.none)
          ..add(restriction);
      }
    }
    state = state.copyWith(healthRestrictions: newRestrictions);
  }

  void addFavoriteMuscleGroup(String muscleGroup) {
    final newFavorites = List<String>.from(state.favoriteMuscleGroups)
      ..add(muscleGroup);
    state = state.copyWith(favoriteMuscleGroups: newFavorites);
  }

  void removeFavoriteMuscleGroup(String muscleGroup) {
    final newFavorites = List<String>.from(state.favoriteMuscleGroups)
      ..remove(muscleGroup);
    state = state.copyWith(favoriteMuscleGroups: newFavorites);
  }

  void addDislikedExercise(String exercise) {
    final newDisliked = List<String>.from(state.dislikedExercises)
      ..add(exercise);
    state = state.copyWith(dislikedExercises: newDisliked);
  }

  void removeDislikedExercise(String exercise) {
    final newDisliked = List<String>.from(state.dislikedExercises)
      ..remove(exercise);
    state = state.copyWith(dislikedExercises: newDisliked);
  }

  // Новый метод для очистки всех нелюбимых упражнений
  void clearDislikedExercises() {
    state = state.copyWith(dislikedExercises: const []);
  }

  // Новый метод для очистки всех любимых групп мышц
  void clearFavoriteMuscleGroups() {
    state = state.copyWith(favoriteMuscleGroups: const []);
  }

  // Новый метод для сброса всех настроек анкеты
  void resetQuestionnaire() {
    state = const UserPreferences();
  }

  // Новый метод для проверки, заполнены ли все обязательные поля
  bool areMandatoryFieldsFilled() {
    return state.gender != null &&
        state.age != null &&
        state.height != null &&
        state.weight != null &&
        state.goal != null &&
        state.activityLevel != null &&
        state.experienceLevel != null &&
        state.availableEquipment.isNotEmpty &&
        state.daysPerWeek != null &&
        state.sessionDuration != null;
  }

  // Новый метод для получения статистики анкеты
  Map<String, dynamic> getQuestionnaireStats() {
    return {
      'bmi': state.bmi,
      'bmiCategory': state.bmiCategory,
      'bmr': state.bmr,
      'dailyCalories': state.dailyCalories,
      'recommendedProtein': state.recommendedDailyProtein,
      'recommendedWater': state.recommendedDailyWater,
      'filledFields': {
        'basic': state.gender != null && state.age != null && state.height != null && state.weight != null,
        'goal': state.goal != null && state.activityLevel != null,
        'experience': state.experienceLevel != null && state.bodyType != null,
        'equipment': state.availableEquipment.isNotEmpty,
        'schedule': state.daysPerWeek != null && state.sessionDuration != null,
      },
    };
  }

  void reset() {
    state = const UserPreferences();
  }
}

final questionnaireProvider = StateNotifierProvider<QuestionnaireNotifier, UserPreferences>(
  (ref) => QuestionnaireNotifier(),
);