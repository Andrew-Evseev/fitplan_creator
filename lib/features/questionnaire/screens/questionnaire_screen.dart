import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitplan_creator/core/widgets/custom_button.dart';
import 'package:fitplan_creator/core/widgets/loading_indicator.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'package:fitplan_creator/features/questionnaire/providers/questionnaire_provider.dart';
import 'package:fitplan_creator/features/planner/providers/planner_provider.dart';

class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  ConsumerState<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      _generatePlan();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _generatePlan() async {
    // Проверка в самом начале
    if (!mounted) return;
    
    final prefs = ref.read(questionnaireProvider);
    
    if (prefs.isComplete) {
      // Сохраняем локальные переменные для безопасного использования
      final localContext = context;
      
      // Показываем индикатор загрузки
      showDialog(
        context: localContext,
        barrierDismissible: false,
        builder: (context) => const LoadingIndicator(message: 'Создаем ваш план...'),
      );

      try {
        // Генерируем план
        await ref.read(plannerProvider.notifier).setUserPreferences(prefs);
        
        // Проверяем mounted перед закрытием диалога
        if (mounted) {
          Navigator.of(localContext, rootNavigator: true).pop();
          // Проверяем mounted перед переходом
          if (mounted) {
            GoRouter.of(localContext).go('/loading');
          }
        }
      } catch (e) {
        // Проверяем mounted перед обработкой ошибки
        if (mounted) {
          Navigator.of(localContext, rootNavigator: true).pop();
          // Используем addPostFrameCallback для безопасного показа SnackBar
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(localContext).showSnackBar(
                SnackBar(
                  content: Text('Ошибка при создании плана: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
        }
      }
    }
  }

  Widget _buildGoalStep() {
    final prefs = ref.watch(questionnaireProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Какова ваша основная цель?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Выберите цель, которая лучше всего описывает ваши намерения',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
        Column(
          children: UserGoal.values.map((goal) {
            final isSelected = prefs.goal == goal;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isSelected ? Colors.blue[50] : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? Colors.blue : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  _getGoalIcon(goal),
                  color: isSelected ? Colors.blue : Colors.grey,
                ),
                title: Text(
                  goal.displayName,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue : Colors.black,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.blue)
                    : null,
                onTap: () {
                  ref.read(questionnaireProvider.notifier).setGoal(goal);
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExperienceStep() {
    final prefs = ref.watch(questionnaireProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Ваш уровень опыта',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Выберите уровень, который лучше всего соответствует вашему опыту тренировок',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
        Column(
          children: ExperienceLevel.values.map((level) {
            final isSelected = prefs.experienceLevel == level;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isSelected ? Colors.blue[50] : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? Colors.blue : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.blue : Colors.grey[200],
                  ),
                  child: Center(
                    child: Text(
                      (ExperienceLevel.values.indexOf(level) + 1).toString(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  level.displayName,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue : Colors.black,
                  ),
                ),
                subtitle: Text(level.description),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.blue)
                    : null,
                onTap: () {
                  ref.read(questionnaireProvider.notifier).setExperienceLevel(level);
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEquipmentStep() {
    final prefs = ref.watch(questionnaireProvider);
    final selectedEquipment = prefs.availableEquipment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Какое оборудование у вас есть?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Выберите все доступное оборудование (можно выбрать несколько)',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Equipment.values.map((equipment) {
            final isSelected = selectedEquipment.contains(equipment);
            return FilterChip(
              label: Text(equipment.displayName),
              selected: isSelected,
              onSelected: (_) {
                ref.read(questionnaireProvider.notifier).toggleEquipment(equipment);
              },
              selectedColor: Colors.blue[100],
              checkmarkColor: Colors.blue,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey[700],
              ),
              avatar: isSelected
                  ? const Icon(Icons.check, size: 18, color: Colors.blue)
                  : null,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        if (selectedEquipment.contains(Equipment.none))
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Выбрано "Без оборудования". Будут предложены только упражнения с собственным весом.',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildScheduleStep() {
    final prefs = ref.watch(questionnaireProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Ваш график тренировок',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Настройте частоту и длительность тренировок',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),

        // Дни в неделю
        const Text(
          'Сколько дней в неделю вы готовы тренироваться?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [3, 4, 5, 6].map((days) {
            final isSelected = prefs.daysPerWeek == days;
            return Column(
              children: [
                GestureDetector(
                  onTap: () {
                    ref.read(questionnaireProvider.notifier).setDaysPerWeek(days);
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.blue : Colors.grey[200],
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$days',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$days дней',
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

        // Длительность тренировки
        const Text(
          'Сколько времени вы готовы уделять каждой тренировке?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDurationOption(prefs, 30, '30 мин'),
            _buildDurationOption(prefs, 45, '45 мин'),
            _buildDurationOption(prefs, 60, '60 мин'),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationOption(UserPreferences prefs, int minutes, String label) {
    final isSelected = prefs.sessionDuration == minutes;
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            ref.read(questionnaireProvider.notifier).setSessionDuration(minutes);
          },
          child: Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? Colors.blue : Colors.grey[200],
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  IconData _getGoalIcon(UserGoal goal) {
    switch (goal) {
      case UserGoal.weightLoss:
        return Icons.monitor_weight;
      case UserGoal.muscleGain:
        return Icons.fitness_center;
      case UserGoal.endurance:
        return Icons.directions_run;
      case UserGoal.strength:
        return Icons.bolt;
      case UserGoal.generalFitness:
        return Icons.health_and_safety;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(questionnaireProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание плана тренировок'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              context.go('/welcome');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentStep ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Шаг ${_currentStep + 1} из 4',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '${((_currentStep + 1) / 4 * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildGoalStep(),
                  _buildExperienceStep(),
                  _buildEquipmentStep(),
                  _buildScheduleStep(),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        child: const Text('Назад'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: _currentStep == 3 ? 'Создать план' : 'Далее',
                      onPressed: () {
                        switch (_currentStep) {
                          case 0:
                            if (prefs.goal == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Пожалуйста, выберите цель'),
                                ),
                              );
                              return;
                            }
                            break;
                          case 1:
                            if (prefs.experienceLevel == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Пожалуйста, выберите уровень опыта'),
                                ),
                              );
                              return;
                            }
                            break;
                          case 2:
                            if (prefs.availableEquipment.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Пожалуйста, выберите хотя бы один вариант оборудования'),
                                ),
                              );
                              return;
                            }
                            break;
                          case 3:
                            if (prefs.daysPerWeek == null || prefs.sessionDuration == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Пожалуйста, укажите дни и длительность тренировок'),
                                ),
                              );
                              return;
                            }
                            break;
                        }
                        _nextStep();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}