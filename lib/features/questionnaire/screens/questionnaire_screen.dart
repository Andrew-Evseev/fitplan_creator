import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'package:fitplan_creator/features/questionnaire/screens/providers/questionnaire_provider.dart';

class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  ConsumerState<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Выбор цели тренировок',
      'type': 'single',
      'options': UserGoal.values,
    },
    {
      'title': 'Ваш опыт тренировок',
      'type': 'single',
      'options': ExperienceLevel.values,
    },
    {
      'title': 'Доступное оборудование',
      'type': 'multiple',
      'options': Equipment.values,
    },
    {
      'title': 'График тренировок',
      'type': 'schedule',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Анкета - Шаг ${_currentStep + 1} из ${_steps.length}'),
      ),
      body: Column(
        children: [
          // Прогресс-бар
          LinearProgressIndicator(
            value: (_currentStep + 1) / _steps.length,
            backgroundColor: Colors.grey[200],
            color: Colors.green,
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildGoalStep(),
                _buildExperienceStep(),
                _buildEquipmentStep(),
                _buildScheduleStep(),
              ],
            ),
          ),

          // Кнопки навигации
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  ElevatedButton(
                    onPressed: _goToPreviousStep,
                    child: const Text('Назад'),
                  )
                else
                  const SizedBox(width: 80),

                ElevatedButton(
                  onPressed: _currentStep < _steps.length - 1
                      ? _goToNextStep
                      : _completeQuestionnaire,
                  child: Text(
                    _currentStep < _steps.length - 1 ? 'Далее' : 'Завершить',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep() {
    final currentGoal = ref.watch(questionnaireProvider).goal;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Выбор цели тренировок',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...UserGoal.values.map((goal) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: currentGoal == goal ? Colors.green[50] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: currentGoal == goal ? Colors.green : Colors.grey[300]!,
                  width: currentGoal == goal ? 2 : 1,
                ),
              ),
              child: ListTile(
                title: Text(goal.displayName),
                trailing: Radio<UserGoal>(
                  value: goal,
                  groupValue: currentGoal,
                  onChanged: (value) {
                    ref.read(questionnaireProvider.notifier).setGoal(value!);
                  },
                ),
                onTap: () {
                  ref.read(questionnaireProvider.notifier).setGoal(goal);
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildExperienceStep() {
    final currentLevel = ref.watch(questionnaireProvider).experienceLevel;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Ваш опыт тренировок',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...ExperienceLevel.values.map((level) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: currentLevel == level ? Colors.green[50] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: currentLevel == level ? Colors.green : Colors.grey[300]!,
                  width: currentLevel == level ? 2 : 1,
                ),
              ),
              child: ListTile(
                title: Text(level.displayName),
                trailing: Radio<ExperienceLevel>(
                  value: level,
                  groupValue: currentLevel,
                  onChanged: (value) {
                    ref.read(questionnaireProvider.notifier).setExperienceLevel(value!);
                  },
                ),
                onTap: () {
                  ref.read(questionnaireProvider.notifier).setExperienceLevel(level);
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEquipmentStep() {
    final currentEquipment = ref.watch(questionnaireProvider).availableEquipment;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Доступное оборудование',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...Equipment.values.map((equipment) {
            final isSelected = currentEquipment.contains(equipment);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: isSelected ? Colors.green[50] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? Colors.green : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                title: Text(equipment.displayName),
                trailing: Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    ref.read(questionnaireProvider.notifier).toggleEquipment(equipment);
                  },
                ),
                onTap: () {
                  ref.read(questionnaireProvider.notifier).toggleEquipment(equipment);
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildScheduleStep() {
    final prefs = ref.watch(questionnaireProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'График тренировок',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          const Text(
            'Дней в неделю:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [3, 4, 5, 6].map((days) {
              return ChoiceChip(
                label: Text('$days дней'),
                selected: prefs.daysPerWeek == days,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(questionnaireProvider.notifier).setDaysPerWeek(days);
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 30),
          const Text(
            'Длительность тренировки:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [30, 45, 60].map((minutes) {
              return ChoiceChip(
                label: Text('$minutes мин'),
                selected: prefs.sessionDuration == minutes,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(questionnaireProvider.notifier).setSessionDuration(minutes);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _goToNextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeQuestionnaire() {
    // Переход на экран загрузки
    context.go('/loading');
  }
}
