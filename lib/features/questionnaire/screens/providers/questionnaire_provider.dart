import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';

class QuestionnaireNotifier extends StateNotifier<UserPreferences> {
  QuestionnaireNotifier() : super(UserPreferences());

  void setGoal(UserGoal goal) {
    state = state.copyWith(goal: goal);
  }

  void setExperienceLevel(ExperienceLevel level) {
    state = state.copyWith(experienceLevel: level);
  }

  void toggleEquipment(Equipment equipment) {
    final currentEquipment = List<Equipment>.from(state.availableEquipment);
    if (currentEquipment.contains(equipment)) {
      currentEquipment.remove(equipment);
    } else {
      currentEquipment.add(equipment);
    }
    state = state.copyWith(availableEquipment: currentEquipment);
  }

  void setDaysPerWeek(int days) {
    state = state.copyWith(daysPerWeek: days);
  }

  void setSessionDuration(int minutes) {
    state = state.copyWith(sessionDuration: minutes);
  }

  void reset() {
    state = UserPreferences();
  }
}

final questionnaireProvider =
    StateNotifierProvider<QuestionnaireNotifier, UserPreferences>(
  (ref) => QuestionnaireNotifier(),
);
