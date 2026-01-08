// lib/features/questionnaire/screens/extended_questionnaire_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitplan_creator/core/widgets/custom_button.dart';
import 'package:fitplan_creator/core/widgets/loading_indicator.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'package:fitplan_creator/features/questionnaire/providers/questionnaire_provider.dart';
import 'package:fitplan_creator/features/planner/providers/planner_provider.dart';

class ExtendedQuestionnaireScreen extends ConsumerStatefulWidget {
  const ExtendedQuestionnaireScreen({super.key});

  @override
  ConsumerState<ExtendedQuestionnaireScreen> createState() => _ExtendedQuestionnaireScreenState();
}

class _ExtendedQuestionnaireScreenState extends ConsumerState<ExtendedQuestionnaireScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  final List<GlobalKey<FormState>> _formKeys = List.generate(7, (_) => GlobalKey<FormState>());

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
    // Валидация текущего шага
    if (_currentStep < 6) {
      if (_validateCurrentStep()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentStep++;
        });
      }
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

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Основные данные
        return _validateBasicInfoStep();
      case 1: // Цель и активность
        return _validateGoalStep();
      case 2: // Уровень подготовки
        return _validateExperienceStep();
      case 3: // Оборудование
        return _validateEquipmentStep();
      case 4: // Ограничения по здоровью
        return true; // Необязательный шаг
      case 5: // Предпочтения
        return true; // Необязательный шаг
      case 6: // График
        return _validateScheduleStep();
      default:
        return false;
    }
  }

  bool _validateBasicInfoStep() {
    final prefs = ref.read(questionnaireProvider);
    return prefs.gender != null &&
        prefs.age != null &&
        prefs.age! >= 10 &&
        prefs.age! <= 100 &&
        prefs.height != null &&
        prefs.height! >= 100 &&
        prefs.height! <= 250 &&
        prefs.weight != null &&
        prefs.weight! >= 30 &&
        prefs.weight! <= 300;
  }

  bool _validateGoalStep() {
    final prefs = ref.read(questionnaireProvider);
    return prefs.goal != null && prefs.activityLevel != null;
  }

  bool _validateExperienceStep() {
    final prefs = ref.read(questionnaireProvider);
    return prefs.experienceLevel != null && prefs.bodyType != null;
  }

  bool _validateEquipmentStep() {
    final prefs = ref.read(questionnaireProvider);
    return prefs.availableEquipment.isNotEmpty;
  }

  bool _validateScheduleStep() {
    final prefs = ref.read(questionnaireProvider);
    return prefs.daysPerWeek != null && prefs.sessionDuration != null;
  }

  Future<void> _generatePlan() async {
    final prefs = ref.read(questionnaireProvider);
    
    // Проверяем только обязательные поля
    final isComplete = prefs.gender != null &&
        prefs.age != null &&
        prefs.height != null &&
        prefs.weight != null &&
        prefs.goal != null &&
        prefs.activityLevel != null &&
        prefs.experienceLevel != null &&
        prefs.availableEquipment.isNotEmpty &&
        prefs.daysPerWeek != null &&
        prefs.sessionDuration != null;
    
    if (!isComplete) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, заполните все обязательные поля'),
        ),
      );
      return;
    }
    
    // Сохраняем контекст до асинхронных операций
    final BuildContext currentContext = context;
    
    // Показываем индикатор загрузки
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (context) => const LoadingIndicator(message: 'Создаем ваш план...'),
    );

    try {
      // Генерируем план
      await ref.read(plannerProvider.notifier).setUserPreferences(prefs);
      
      // Закрываем диалог и переходим
      if (mounted) {
        Navigator.of(currentContext, rootNavigator: true).pop();
        GoRouter.of(currentContext).go('/loading');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(currentContext, rootNavigator: true).pop();
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Ошибка при создании плана: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Шаг 1: Основные данные
  Widget _buildBasicInfoStep() {
    final prefs = ref.watch(questionnaireProvider);
    
    return Form(
      key: _formKeys[0],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Основные данные',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Эта информация поможет создать персонализированный план',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            // Пол
            const Text(
              'Пол',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Gender.values.map((gender) {
                final isSelected = prefs.gender == gender;
                return FilterChip(
                  label: Text(gender.displayName),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(questionnaireProvider.notifier).setGender(gender);
                  },
                  selectedColor: Colors.blue[100],
                  checkmarkColor: Colors.blue,
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Возраст
            const Text(
              'Возраст',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: prefs.age?.toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Введите возраст (10-100)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                final age = int.tryParse(value);
                if (age != null && age >= 10 && age <= 100) {
                  ref.read(questionnaireProvider.notifier).setAge(age);
                }
              },
              validator: (value) {
                final age = int.tryParse(value ?? '');
                if (age == null || age < 10 || age > 100) {
                  return 'Введите возраст от 10 до 100 лет';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Рост и вес в строке
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Рост (см)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: prefs.height?.toStringAsFixed(0),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '170',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          final height = double.tryParse(value);
                          if (height != null && height >= 100 && height <= 250) {
                            ref.read(questionnaireProvider.notifier).setHeight(height);
                          }
                        },
                        validator: (value) {
                          final height = double.tryParse(value ?? '');
                          if (height == null || height < 100 || height > 250) {
                            return '100-250 см';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Вес (кг)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: prefs.weight?.toStringAsFixed(0),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '70',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          final weight = double.tryParse(value);
                          if (weight != null && weight >= 30 && weight <= 300) {
                            ref.read(questionnaireProvider.notifier).setWeight(weight);
                          }
                        },
                        validator: (value) {
                          final weight = double.tryParse(value ?? '');
                          if (weight == null || weight < 30 || weight > 300) {
                            return '30-300 кг';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (prefs.bmi != null && prefs.weight != null && prefs.height != null)
              Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Информация:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('ИМТ: ${prefs.bmi!.toStringAsFixed(1)}'),
                        Text('Рост: ${prefs.height!.toInt()} см'),
                        Text('Вес: ${prefs.weight!.toInt()} кг'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Шаг 2: Цель и активность
  Widget _buildGoalAndActivityStep() {
    final prefs = ref.watch(questionnaireProvider);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Цель и активность',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите свою основную цель и уровень ежедневной активности',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Цель
          const Text(
            'Какова ваша основная цель?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
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
          
          const SizedBox(height: 32),
          
          // Уровень активности
          const Text(
            'Ваш уровень ежедневной активности',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: ActivityLevel.values.map((level) {
              final isSelected = prefs.activityLevel == level;
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
                    Icons.directions_walk,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  title: Text(
                    level.displayName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.blue : Colors.black,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () {
                    ref.read(questionnaireProvider.notifier).setActivityLevel(level);
                  },
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Желаемый вес (опционально)
          const Text(
            'Желаемый вес (кг)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: prefs.targetWeight?.toStringAsFixed(0),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Оставьте пустым, если не знаете',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                final targetWeight = double.tryParse(value);
                if (targetWeight != null && targetWeight >= 30 && targetWeight <= 300) {
                  ref.read(questionnaireProvider.notifier).setTargetWeight(targetWeight);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // Шаг 3: Уровень подготовки
  Widget _buildExperienceStep() {
    final prefs = ref.watch(questionnaireProvider);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Уровень подготовки',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Оцените свой текущий уровень подготовки и тип телосложения',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Уровень опыта
          const Text(
            'Ваш уровень опыта в тренировках',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
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
          
          const SizedBox(height: 32),
          
          // Тип телосложения
          const Text(
            'Тип телосложения',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: BodyType.values.map((type) {
              final isSelected = prefs.bodyType == type;
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
                    _getBodyTypeIcon(type),
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  title: Text(
                    type.displayName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.blue : Colors.black,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () {
                    ref.read(questionnaireProvider.notifier).setBodyType(type);
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Шаг 4: Оборудование
  Widget _buildEquipmentStep() {
    final prefs = ref.watch(questionnaireProvider);
    final selectedEquipment = prefs.availableEquipment;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Оборудование',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Какое оборудование у вас есть для тренировок?',
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
      ),
    );
  }

  // Шаг 5: Ограничения по здоровью
  Widget _buildHealthRestrictionsStep() {
    final prefs = ref.watch(questionnaireProvider);
    final selectedRestrictions = prefs.healthRestrictions;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Ограничения по здоровью',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Укажите проблемы со здоровьем, чтобы исключить опасные упражнения',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HealthRestriction.values.map((restriction) {
              final isSelected = selectedRestrictions.contains(restriction);
              return FilterChip(
                label: Text(restriction.displayName),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(questionnaireProvider.notifier).toggleHealthRestriction(restriction);
                },
                selectedColor: isSelected && restriction != HealthRestriction.none 
                    ? Colors.orange[100] 
                    : Colors.blue[100],
                checkmarkColor: isSelected && restriction != HealthRestriction.none 
                    ? Colors.orange 
                    : Colors.blue,
                labelStyle: TextStyle(
                  color: isSelected 
                      ? (restriction != HealthRestriction.none ? Colors.orange : Colors.blue)
                      : Colors.grey[700],
                ),
                avatar: isSelected
                    ? Icon(Icons.check, size: 18, 
                        color: restriction != HealthRestriction.none ? Colors.orange : Colors.blue)
                    : null,
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          if (selectedRestrictions.contains(HealthRestriction.none))
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ограничений по здоровью нет. Будут доступны все упражнения.',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (selectedRestrictions.isNotEmpty && !selectedRestrictions.contains(HealthRestriction.none))
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.medical_services, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Упражнения, которые могут навредить указанным суставам/мышцам, будут исключены.',
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
      ),
    );
  }

  // Шаг 6: Предпочтения
  Widget _buildPreferencesStep() {
    final prefs = ref.watch(questionnaireProvider);
    
    // Группы мышц для выбора
    final muscleGroups = [
      'Грудь', 'Спина', 'Плечи', 'Бицепс', 'Трицепс', 
      'Ноги', 'Ягодицы', 'Пресс', 'Кардио'
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Предпочтения',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Укажите ваши предпочтения для персонализации плана',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Любимые группы мышц
          const Text(
            'Любимые группы мышц (можно выбрать несколько)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: muscleGroups.map((muscleGroup) {
              final isSelected = prefs.favoriteMuscleGroups.contains(muscleGroup);
              return FilterChip(
                label: Text(muscleGroup),
                selected: isSelected,
                onSelected: (_) {
                  if (isSelected) {
                    ref.read(questionnaireProvider.notifier).removeFavoriteMuscleGroup(muscleGroup);
                  } else {
                    ref.read(questionnaireProvider.notifier).addFavoriteMuscleGroup(muscleGroup);
                  }
                },
                selectedColor: Colors.green[100],
                checkmarkColor: Colors.green,
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Нелюбимые упражнения (текстовое поле)
          const Text(
            'Нелюбимые упражнения',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Введите названия упражнений, которые вы не хотите видеть в плане (через запятую)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: prefs.dislikedExercises.join(', '),
            decoration: InputDecoration(
              hintText: 'Например: берпи, планка, выпады',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              // Создаем новый список упражнений из ввода
              final exercises = value.split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
              
              // Сначала очищаем старый список
              ref.read(questionnaireProvider.notifier).clearDislikedExercises();
              
              // Затем добавляем новые упражнения
              for (final exercise in exercises) {
                ref.read(questionnaireProvider.notifier).addDislikedExercise(exercise);
              }
            },
          ),
          
          const SizedBox(height: 16),
          if (prefs.favoriteMuscleGroups.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.favorite, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Вы выбрали любимые группы мышц: ${prefs.favoriteMuscleGroups.join(', ')}',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Шаг 7: График
  Widget _buildScheduleStep() {
    final prefs = ref.watch(questionnaireProvider);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'График тренировок',
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
            children: [2, 3, 4, 5, 6].map((days) {
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
              _buildDurationOption(prefs, 90, '90 мин'),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Резюме выбора
          if (prefs.daysPerWeek != null && prefs.sessionDuration != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ваш график тренировок:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('• ${prefs.daysPerWeek} дней в неделю'),
                  Text('• ${prefs.sessionDuration} минут на тренировку'),
                  Text('• Общее время в неделю: ${prefs.daysPerWeek! * prefs.sessionDuration!} минут'),
                ],
              ),
            ),
        ],
      ),
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

  // Иконки для целей
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

  // Иконки для типов телосложения
  IconData _getBodyTypeIcon(BodyType type) {
    switch (type) {
      case BodyType.ectomorph:
        return Icons.linear_scale;
      case BodyType.mesomorph:
        return Icons.fitness_center;
      case BodyType.endomorph:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Расширенная анкета'),
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
            // Индикатор прогресса
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 2),
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
                    'Шаг ${_currentStep + 1} из 7',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '${((_currentStep + 1) / 7 * 100).toInt()}%',
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
            
            // Контент анкеты
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildBasicInfoStep(),
                  _buildGoalAndActivityStep(),
                  _buildExperienceStep(),
                  _buildEquipmentStep(),
                  _buildHealthRestrictionsStep(),
                  _buildPreferencesStep(),
                  _buildScheduleStep(),
                ],
              ),
            ),
            
            // Кнопки навигации
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
                      text: _currentStep == 6 ? 'Создать план' : 'Далее',
                      onPressed: _nextStep,
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