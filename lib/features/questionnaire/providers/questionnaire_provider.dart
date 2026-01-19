// lib/features/questionnaire/providers/questionnaire_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'package:fitplan_creator/data/repositories/preferences_repository.dart';
import 'package:fitplan_creator/core/supabase/supabase_client.dart' as supabase;

class QuestionnaireNotifier extends StateNotifier<UserPreferences> {
  final _preferencesRepo = PreferencesRepository();
  
  QuestionnaireNotifier() : super(const UserPreferences()) {
    _loadPreferences();
  }

  /// Загрузить предпочтения из Supabase
  Future<void> _loadPreferences() async {
    try {
      final userId = supabase.AppSupabaseClient.instance.currentUserId;
      if (userId == null) {
        // Пользователь не авторизован, используем пустые предпочтения
        return;
      }

      final preferences = await _preferencesRepo.getPreferences(userId);
      if (preferences != null) {
        state = preferences;
      }
    } catch (e) {
      // В случае ошибки используем пустые предпочтения
      print('Ошибка при загрузке предпочтений: $e');
    }
  }

  /// Сохранить предпочтения в Supabase
  Future<void> savePreferences() async {
    try {
      final userId = supabase.AppSupabaseClient.instance.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      await _preferencesRepo.savePreferences(state, userId);
    } catch (e) {
      throw Exception('Ошибка при сохранении предпочтений: $e');
    }
  }

  // ==================== БАЗОВЫЕ ДАННЫЕ ====================
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

  // ==================== ЦЕЛИ И АКТИВНОСТЬ ====================
  void setGoal(UserGoal goal) {
    state = state.copyWith(goal: goal);
  }

  void setActivityLevel(ActivityLevel level) {
    state = state.copyWith(activityLevel: level);
  }

  // ==================== ОПЫТ И ТЕЛОСЛОЖЕНИЕ ====================
  void setExperienceLevel(ExperienceLevel level) {
    state = state.copyWith(experienceLevel: level);
  }

  void setBodyType(BodyType bodyType) {
    state = state.copyWith(bodyType: bodyType);
  }

  // ==================== МЕСТО ТРЕНИРОВОК И ОБОРУДОВАНИЕ ====================
  void setTrainingLocation(TrainingLocation location) {
    // При выборе места тренировок автоматически добавляем соответствующее оборудование
    final equipment = UserPreferences.getEquipmentByLocation(location);
    
    state = state.copyWith(
      trainingLocation: location,
      availableEquipment: equipment,
    );
  }

  void toggleEquipment(Equipment equipment) {
    final List<Equipment> newEquipment;
    if (state.availableEquipment.contains(equipment)) {
      newEquipment = List.from(state.availableEquipment)..remove(equipment);
    } else {
      newEquipment = List.from(state.availableEquipment)..add(equipment);
    }
    state = state.copyWith(availableEquipment: newEquipment);
  }

  // Добавить несколько единиц оборудования
  void addMultipleEquipment(List<Equipment> equipmentList) {
    final newEquipment = List<Equipment>.from(state.availableEquipment)
      ..addAll(equipmentList.where((e) => !state.availableEquipment.contains(e)));
    state = state.copyWith(availableEquipment: newEquipment);
  }

  // Удалить все оборудование
  void clearEquipment() {
    state = state.copyWith(availableEquipment: const []);
  }

  // ==================== ОГРАНИЧЕНИЯ ПО ЗДОРОВЬЮ ====================
  void toggleHealthRestriction(HealthRestriction restriction) {
    final List<HealthRestriction> newRestrictions;
    if (state.healthRestrictions.contains(restriction)) {
      newRestrictions = List.from(state.healthRestrictions)..remove(restriction);
    } else {
      newRestrictions = List.from(state.healthRestrictions)..add(restriction);
    }
    state = state.copyWith(healthRestrictions: newRestrictions);
  }

  // ==================== ПРЕДПОЧТЕНИЯ ====================
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

  // ==================== ГРАФИК ТРЕНИРОВОК ====================
  void setDaysPerWeek(int days) {
    state = state.copyWith(daysPerWeek: days);
  }

  void setSessionDuration(int minutes) {
    state = state.copyWith(sessionDuration: minutes);
  }

  // ==================== СИСТЕМА ТРЕНИРОВОК ====================
  void setPreferredSystem(TrainingSystem system) {
    state = state.copyWith(preferredSystem: system);
  }

  // ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================
  void clearDislikedExercises() {
    state = state.copyWith(dislikedExercises: const []);
  }

  void clearFavoriteMuscleGroups() {
    state = state.copyWith(favoriteMuscleGroups: const []);
  }

  void resetQuestionnaire() {
    state = const UserPreferences();
  }

  // Проверка заполнения обязательных полей
  bool areMandatoryFieldsFilled() {
    return state.gender != null &&
        state.age != null &&
        state.height != null &&
        state.weight != null &&
        state.goal != null &&
        state.activityLevel != null &&
        state.experienceLevel != null &&
        state.trainingLocation != null &&
        state.availableEquipment.isNotEmpty &&
        state.daysPerWeek != null &&
        state.sessionDuration != null;
  }

  // Получить статистику анкеты
  Map<String, dynamic> getQuestionnaireStats() {
    return {
      'bmi': state.bmi,
      'bmiCategory': state.bmiCategory,
      'bmr': state.bmr,
      'dailyCalories': state.dailyCalories,
      'recommendedProtein': state.recommendedDailyProtein,
      'recommendedWater': state.recommendedDailyWater,
      'recommendedSystem': state.recommendedSystem.displayName,
      'filledFields': {
        'basic': state.gender != null && state.age != null && state.height != null && state.weight != null,
        'goal': state.goal != null && state.activityLevel != null,
        'experience': state.experienceLevel != null && state.bodyType != null,
        'location': state.trainingLocation != null,
        'equipment': state.availableEquipment.isNotEmpty,
        'schedule': state.daysPerWeek != null && state.sessionDuration != null,
      },
      'recommendations': state.recommendations,
    };
  }

  // Получить рекомендуемую систему тренировок
  TrainingSystem getRecommendedTrainingSystem() {
    return state.recommendedSystem;
  }

  // Получить оборудование для выбранного места тренировок
  List<Equipment> getEquipmentForSelectedLocation() {
    if (state.trainingLocation == null) return [];
    return UserPreferences.getEquipmentByLocation(state.trainingLocation!);
  }

  // Проверить, выбрано ли конкретное оборудование
  bool isEquipmentSelected(Equipment equipment) {
    return state.availableEquipment.contains(equipment);
  }

  void reset() {
    state = const UserPreferences();
  }
  
  // Обновить все предпочтения из существующего объекта
  void updatePreferences(UserPreferences preferences) {
    state = preferences;
  }
}

final questionnaireProvider = StateNotifierProvider<QuestionnaireNotifier, UserPreferences>(
  (ref) => QuestionnaireNotifier(),
);