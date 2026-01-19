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
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final prefs = ref.read(questionnaireProvider);
    _ageController.text = prefs.age?.toString() ?? '';
    _heightController.text = prefs.height?.toStringAsFixed(0) ?? '';
    _weightController.text = prefs.weight?.toStringAsFixed(0) ?? '';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 6) {
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
    } else {
      context.go('/welcome');
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Основные данные
        return _formKeys[0].currentState?.validate() ?? false;
      case 1: // Цель и активность
        return _validateGoalStep();
      case 2: // Уровень подготовки
        return _validateExperienceStep();
      case 3: // Место тренировок и оборудование
        return _validateEquipmentStep();
      case 4: // Ограничения по здоровью
        return true; // Необязательный шаг
      case 5: // Предпочтения
        return true; // Необязательный шаг
      case 6: // График и система
        return _validateScheduleStep();
      default:
        return false;
    }
  }

  bool _validateGoalStep() {
    final prefs = ref.read(questionnaireProvider);
    if (prefs.goal == null) {
      _showValidationError('Пожалуйста, выберите цель тренировок');
      return false;
    }
    if (prefs.activityLevel == null) {
      _showValidationError('Пожалуйста, выберите уровень активности');
      return false;
    }
    return true;
  }

  bool _validateExperienceStep() {
    final prefs = ref.read(questionnaireProvider);
    if (prefs.experienceLevel == null) {
      _showValidationError('Пожалуйста, выберите уровень подготовки');
      return false;
    }
    if (prefs.bodyType == null) {
      _showValidationError('Пожалуйста, выберите тип телосложения');
      return false;
    }
    return true;
  }

  bool _validateEquipmentStep() {
    final prefs = ref.read(questionnaireProvider);
    if (prefs.trainingLocation == null) {
      _showValidationError('Пожалуйста, выберите место тренировок');
      return false;
    }
    if (prefs.availableEquipment.isEmpty) {
      _showValidationError('Пожалуйста, выберите хотя бы одно оборудование');
      return false;
    }
    return true;
  }

  bool _validateScheduleStep() {
    final prefs = ref.read(questionnaireProvider);
    if (prefs.daysPerWeek == null) {
      _showValidationError('Пожалуйста, выберите количество тренировок в неделю');
      return false;
    }
    if (prefs.sessionDuration == null) {
      _showValidationError('Пожалуйста, выберите длительность тренировки');
      return false;
    }
    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _generatePlan() async {
    final prefs = ref.read(questionnaireProvider);
    
    if (!prefs.isComplete) {
      _showValidationError('Пожалуйста, заполните все обязательные поля');
      return;
    }
    
    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingIndicator(message: 'Создаем ваш план...'),
    );

    try {
      // Сохраняем preferences в Supabase
      print('💾 Сохранение preferences в Supabase...');
      await ref.read(questionnaireProvider.notifier).savePreferences();
      print('✅ Preferences сохранены');
      
      // Генерируем план
      await ref.read(plannerProvider.notifier).setUserPreferences(prefs);
      
      // Закрываем диалог и переходим
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        GoRouter.of(context).go('/loading');
      }
    } catch (e) {
      print('❌ Ошибка при сохранении preferences или создании плана: $e');
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showValidationError('Ошибка при создании плана: $e');
      }
    }
  }

  // Шаг 1: Основные данные
  Widget _buildBasicInfoStep() {
    final prefs = ref.watch(questionnaireProvider);
    
    return Form(
      key: _formKeys[0],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              '👤 Основные данные',
              style: TextStyle(
                fontSize: 28,
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
              spacing: 12,
              runSpacing: 12,
              children: Gender.values.map((gender) {
                final isSelected = prefs.gender == gender;
                return ChoiceChip(
                  label: Text(gender.displayName),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(questionnaireProvider.notifier).setGender(gender);
                  },
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),
            
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
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Введите возраст',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.cake),
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
            
            // Рост и вес
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
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '170',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.height),
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
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '70',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.monitor_weight),
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
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getBMIColor(prefs.bmi!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getBMIIcon(prefs.bmi!),
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ИМТ: ${prefs.bmi!.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                prefs.bmiCategory,
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  IconData _getBMIIcon(double bmi) {
    if (bmi < 18.5) return Icons.warning;
    if (bmi < 25) return Icons.check_circle;
    if (bmi < 30) return Icons.warning_amber;
    return Icons.error;
  }

  // Шаг 2: Цель и активность
  Widget _buildGoalAndActivityStep() {
    final prefs = ref.watch(questionnaireProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            '🎯 Цель тренировок',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите свою основную цель',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Горизонтальная строка для целей тренировок (одинаковый размер)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: UserGoal.values.map((goal) {
                final isSelected = prefs.goal == goal;
                return Container(
                  width: 160,
                  height: 120,
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(questionnaireProvider.notifier).setGoal(goal);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getGoalIcon(goal),
                            color: isSelected ? Colors.white : Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Center(
                              child: Text(
                                goal.displayName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.grey[800],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Icon(Icons.check_circle, color: Colors.white, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Уровень активности
          const Text(
            '📊 Уровень ежедневной активности',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите уровень, соответствующий вашему образу жизни',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Вертикальный список для уровня активности (один столбец)
          Column(
            children: ActivityLevel.values.map((level) {
              final isSelected = prefs.activityLevel == level;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    ref.read(questionnaireProvider.notifier).setActivityLevel(level);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_walk,
                          color: isSelected ? Colors.blue : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level.displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: isSelected ? Colors.blue : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                level.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Colors.blue, size: 24),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Шаг 3: Уровень подготовки и телосложение
  Widget _buildExperienceStep() {
    final prefs = ref.watch(questionnaireProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            '🏆 Уровень подготовки',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Оцените свой текущий уровень подготовки',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Горизонтальная строка для уровня подготовки
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ExperienceLevel.values.map((level) {
                final isSelected = prefs.experienceLevel == level;
                return Container(
                  width: 180,
                  height: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(questionnaireProvider.notifier).setExperienceLevel(level);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[50] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
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
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  level.displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isSelected ? Colors.blue : Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: Colors.blue, size: 18),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              level.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Тип телосложения
          const Text(
            '📏 Тип телосложения',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите тип, наиболее соответствующий вашему телу',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Горизонтальная строка для типа телосложения
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BodyType.values.map((type) {
                final isSelected = prefs.bodyType == type;
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(questionnaireProvider.notifier).setBodyType(type);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[50] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getBodyTypeIcon(type),
                            color: isSelected ? Colors.blue : Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            type.displayName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isSelected ? Colors.blue : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Icon(Icons.check_circle, color: Colors.blue, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Шаг 4: Место тренировок и оборудование (ИНТЕЛЛЕКТУАЛЬНЫЙ ВЫБОР)
  Widget _buildEquipmentStep() {
    final prefs = ref.watch(questionnaireProvider);
    final selectedLocation = prefs.trainingLocation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            '🏢 Место тренировок',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите, где вы планируете тренироваться',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Горизонтальная строка для места тренировок
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TrainingLocation.values.map((location) {
                final isSelected = selectedLocation == location;
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(questionnaireProvider.notifier).setTrainingLocation(location);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? _getLocationColor(location) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _getLocationColor(location) : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getLocationIcon(location),
                            color: isSelected ? Colors.white : _getLocationColor(location),
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            location.displayName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.grey[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Icon(Icons.check_circle, color: Colors.white, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Выбор оборудования в зависимости от места
          if (selectedLocation != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getEquipmentTitle(selectedLocation),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEquipmentDescription(selectedLocation),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Оборудование для выбранной локации
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: UserPreferences.getEquipmentByLocation(selectedLocation).map((equipment) {
                    final isSelected = prefs.availableEquipment.contains(equipment);
                    return FilterChip(
                      label: Text(equipment.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(questionnaireProvider.notifier).toggleEquipment(equipment);
                        } else {
                          ref.read(questionnaireProvider.notifier).toggleEquipment(equipment);
                        }
                      },
                      selectedColor: _getLocationColor(selectedLocation),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                      avatar: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    );
                  }).toList(),
                ),
                
                if (selectedLocation == TrainingLocation.home)
                  Column(
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        'Другое оборудование:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Введите другое оборудование, которое у вас есть',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.add),
                        ),
                        onChanged: (value) {
                          // Можно добавить логику для сохранения текстового поля
                        },
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getLocationColor(TrainingLocation location) {
    switch (location) {
      case TrainingLocation.gym:
        return Colors.blue;
      case TrainingLocation.home:
        return Colors.green;
      case TrainingLocation.street:
        return Colors.orange;
      case TrainingLocation.bodyweight:
        return Colors.purple;
    }
  }

  String _getEquipmentTitle(TrainingLocation location) {
    switch (location) {
      case TrainingLocation.gym:
        return '🏋️ Оборудование в зале';
      case TrainingLocation.home:
        return '🏠 Домашнее оборудование';
      case TrainingLocation.street:
        return '🌳 Уличное оборудование';
      case TrainingLocation.bodyweight:
        return '💪 Только с весом тела';
    }
  }

  String _getEquipmentDescription(TrainingLocation location) {
    switch (location) {
      case TrainingLocation.gym:
        return 'Выберите оборудование, которое есть в вашем зале';
      case TrainingLocation.home:
        return 'Выберите оборудование, которое у вас есть дома';
      case TrainingLocation.street:
        return 'Выберите оборудование на вашей площадке';
      case TrainingLocation.bodyweight:
        return 'Тренировки с использованием только веса тела';
    }
  }

  // Шаг 5: Ограничения по здоровью
  Widget _buildHealthRestrictionsStep() {
    final prefs = ref.watch(questionnaireProvider);
    final selectedRestrictions = prefs.healthRestrictions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            '🏥 Ограничения по здоровью',
            style: TextStyle(
              fontSize: 28,
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
          
          // Основные ограничения
          const Text(
            'Основные ограничения:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Ограничения в 2 колонки
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 3.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: HealthRestriction.values
                .where((r) => r != HealthRestriction.none)
                .map((restriction) {
              final isSelected = selectedRestrictions.contains(restriction);
              final displayText = _getHealthRestrictionWithExamples(restriction);
              return GestureDetector(
                onTap: () {
                  ref.read(questionnaireProvider.notifier).toggleHealthRestriction(restriction);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange[50] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.orange : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          displayText,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: isSelected ? Colors.orange[800] : Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Кнопка "Нет ограничений"
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ref.read(questionnaireProvider.notifier).toggleHealthRestriction(HealthRestriction.none);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: selectedRestrictions.contains(HealthRestriction.none)
                      ? Colors.green
                      : Colors.grey,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selectedRestrictions.contains(HealthRestriction.none)
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: selectedRestrictions.contains(HealthRestriction.none)
                        ? Colors.green
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Нет ограничений по здоровью',
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedRestrictions.contains(HealthRestriction.none)
                          ? Colors.green
                          : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (selectedRestrictions.contains(HealthRestriction.none))
            Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Отлично! У вас нет ограничений по здоровью. Все упражнения будут доступны.',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
      'Ноги', 'Ягодицы', 'Пресс', 'Кардио', 'Вся верхняя часть',
      'Вся нижняя часть', 'Корпус', 'Руки', 'Задняя поверхность бедра'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            '⭐ Предпочтения',
            style: TextStyle(
              fontSize: 28,
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
            '💪 Любимые группы мышц',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите группы мышц, которые вы хотите развивать в первую очередь',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
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
                selectedColor: Colors.blue,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Нелюбимые упражнения
          const Text(
            '❌ Нелюбимые упражнения',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Введите названия упражнений, которые вы не хотите видеть в плане',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Например: берпи, планка, выпады, скручивания...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              final exercises = value.split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
              
              ref.read(questionnaireProvider.notifier).clearDislikedExercises();
              for (final exercise in exercises) {
                ref.read(questionnaireProvider.notifier).addDislikedExercise(exercise);
              }
            },
          ),
          
          const SizedBox(height: 16),
          Text(
            'Разделяйте упражнения запятыми',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Шаг 7: График и система тренировок
  Widget _buildScheduleStep() {
    final prefs = ref.watch(questionnaireProvider);
    final recommendedSystem = prefs.recommendedSystem;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            '📅 График тренировок',
            style: TextStyle(
              fontSize: 28,
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
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Подсказка для выбора количества тренировок
          _buildWorkoutFrequencyHint(prefs),
          const SizedBox(height: 16),
          
          // Горизонтальная строка для количества дней (компактные карточки)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [2, 3, 4, 5, 6, 7].map((days) {
                final isSelected = prefs.daysPerWeek == days;
                return Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(questionnaireProvider.notifier).setDaysPerWeek(days);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$days',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                          Text(
                            'дней',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),

          // Длительность тренировки
          const Text(
            'Сколько времени вы готовы уделять каждой тренировке?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Подсказка для выбора длительности
          _buildDurationHint(prefs),
          const SizedBox(height: 16),
          
          // Горизонтальная строка для длительности (компактные карточки)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDurationOption(prefs, 30, '30 мин', Icons.timer),
                _buildDurationOption(prefs, 45, '45 мин', Icons.timer),
                _buildDurationOption(prefs, 60, '60 мин', Icons.timer),
                _buildDurationOption(prefs, 75, '75 мин', Icons.timer),
                _buildDurationOption(prefs, 90, '90 мин', Icons.timer),
              ].map((widget) => Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 8),
                child: widget,
              )).toList(),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Рекомендуемая система тренировок
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎯 Рекомендуемая система тренировок',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  recommendedSystem.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recommendedSystem.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Аудитория: ${recommendedSystem.audience}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Резюме выбора
          if (prefs.daysPerWeek != null && prefs.sessionDuration != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Ваш график тренировок:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.green),
                      const SizedBox(width: 12),
                      Text(
                        '${prefs.daysPerWeek} дней в неделю',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.green),
                      const SizedBox(width: 12),
                      Text(
                        '${prefs.sessionDuration} минут на тренировку',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.green),
                      const SizedBox(width: 12),
                      Text(
                        'Всего: ${prefs.daysPerWeek! * prefs.sessionDuration!} минут в неделю',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDurationOption(UserPreferences prefs, int minutes, String label, IconData icon) {
    final isSelected = prefs.sessionDuration == minutes;
    return GestureDetector(
      onTap: () {
        ref.read(questionnaireProvider.notifier).setSessionDuration(minutes);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
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
        return Icons.straighten;
      case BodyType.mesomorph:
        return Icons.fitness_center;
      case BodyType.endomorph:
        return Icons.circle;
    }
  }

  // Иконки для мест тренировок
  IconData _getLocationIcon(TrainingLocation location) {
    switch (location) {
      case TrainingLocation.gym:
        return Icons.fitness_center;
      case TrainingLocation.home:
        return Icons.home;
      case TrainingLocation.street:
        return Icons.park;
      case TrainingLocation.bodyweight:
        return Icons.self_improvement;
    }
  }
  
  // Получить название ограничения с примерами
  String _getHealthRestrictionWithExamples(HealthRestriction restriction) {
    switch (restriction) {
      case HealthRestriction.back:
        return 'Проблемы со спиной (протрузии, грыжи)';
      case HealthRestriction.knees:
        return 'Проблемы с коленями (артроз, травмы)';
      case HealthRestriction.shoulders:
        return 'Проблемы с плечами (вывихи, артрит)';
      case HealthRestriction.neck:
        return 'Проблемы с шеей (остеохондроз)';
      case HealthRestriction.wrist:
        return 'Проблемы с запястьями (туннельный синдром)';
      case HealthRestriction.elbow:
        return 'Проблемы с локтями (эпикондилит)';
      case HealthRestriction.hip:
        return 'Проблемы с тазобедренными суставами (коксартроз)';
      case HealthRestriction.highBloodPressure:
        return 'Высокое давление (гипертония)';
      case HealthRestriction.heartIssues:
        return 'Проблемы с сердцем (аритмия, ИБС)';
      case HealthRestriction.none:
        return 'Нет ограничений';
    }
  }
  
  // Подсказка для выбора частоты тренировок
  Widget _buildWorkoutFrequencyHint(UserPreferences prefs) {
    final goal = prefs.goal;
    final level = prefs.experienceLevel;
    
    String hintText = '';
    if (goal == UserGoal.muscleGain) {
      if (level == ExperienceLevel.beginner) {
        hintText = '💡 Для набора мышечной массы новичкам рекомендуется 3 тренировки в неделю по 60 минут';
      } else if (level == ExperienceLevel.intermediate || level == ExperienceLevel.advanced) {
        hintText = '💡 Для набора мышечной массы среднему/опытному уровню рекомендуется 4-5 тренировок в неделю по 75-90 минут';
      }
    } else if (goal == UserGoal.weightLoss) {
      hintText = '💡 Для похудения рекомендуется 4-5 тренировок в неделю по 45-60 минут';
    } else if (goal == UserGoal.endurance) {
      hintText = '💡 Для развития выносливости рекомендуется 4-6 тренировок в неделю по 45-60 минут';
    } else if (goal == UserGoal.strength) {
      hintText = '💡 Для увеличения силы рекомендуется 3-4 тренировки в неделю по 60-90 минут';
    } else {
      hintText = '💡 Для общей физической формы рекомендуется 3-4 тренировки в неделю по 45-60 минут';
    }
    
    if (hintText.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hintText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Подсказка для выбора длительности тренировки
  Widget _buildDurationHint(UserPreferences prefs) {
    final goal = prefs.goal;
    final level = prefs.experienceLevel;
    final daysPerWeek = prefs.daysPerWeek;
    
    String hintText = '';
    if (goal == UserGoal.muscleGain) {
      if (level == ExperienceLevel.beginner) {
        hintText = '💡 Новичкам для набора массы достаточно 60 минут на тренировку';
      } else if (level == ExperienceLevel.intermediate || level == ExperienceLevel.advanced) {
        hintText = '💡 Среднему/опытному уровню для набора массы рекомендуется 75-90 минут на тренировку';
      }
    } else if (goal == UserGoal.weightLoss) {
      hintText = '💡 Для похудения оптимально 45-60 минут на тренировку';
    } else if (goal == UserGoal.endurance) {
      hintText = '💡 Для выносливости оптимально 45-60 минут на тренировку';
    } else if (goal == UserGoal.strength) {
      hintText = '💡 Для увеличения силы рекомендуется 60-90 минут на тренировку';
    } else {
      hintText = '💡 Для общей физической формы оптимально 45-60 минут на тренировку';
    }
    
    // Дополнительная подсказка в зависимости от количества дней
    if (daysPerWeek != null) {
      if (daysPerWeek >= 5) {
        hintText += ' При ${daysPerWeek} тренировках в неделю можно уменьшить длительность до 45 минут';
      } else if (daysPerWeek <= 3) {
        hintText += ' При ${daysPerWeek} тренировках в неделю можно увеличить длительность до 75-90 минут';
      }
    }
    
    if (hintText.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hintText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(questionnaireProvider);
    final progress = (_currentStep + 1) / 7;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Расширенная анкета'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        ),
        actions: [
          if (prefs.isComplete)
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Все обязательные поля заполнены!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              tooltip: 'Все поля заполнены',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Индикатор прогресса
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: Colors.grey[50],
              child: Column(
                children: [
                  Row(
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
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    color: Colors.blue,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStepTitle(_currentStep),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Назад'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: _currentStep == 6 ? 'Создать план' : 'Далее',
                      onPressed: _nextStep,
                      icon: _currentStep == 6 ? Icons.done_all : Icons.arrow_forward,
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

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Основные данные';
      case 1:
        return 'Цель тренировок';
      case 2:
        return 'Уровень подготовки';
      case 3:
        return 'Место и оборудование';
      case 4:
        return 'Ограничения по здоровью';
      case 5:
        return 'Предпочтения';
      case 6:
        return 'График тренировок';
      default:
        return '';
    }
  }
}