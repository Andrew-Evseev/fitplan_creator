// lib/features/test/screens/test_generator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'package:fitplan_creator/data/models/workout_plan.dart';
import 'package:fitplan_creator/features/planner/providers/planner_provider.dart';
import 'package:fitplan_creator/features/planner/algorithms/plan_generator.dart';
import 'package:fitplan_creator/data/repositories/training_system_repository.dart';
import 'package:fitplan_creator/data/repositories/workout_repository.dart';

class TestGeneratorScreen extends ConsumerStatefulWidget {
  const TestGeneratorScreen({super.key});

  @override
  ConsumerState<TestGeneratorScreen> createState() => _TestGeneratorScreenState();
}

class _TestGeneratorScreenState extends ConsumerState<TestGeneratorScreen> {
  UserPreferences? _testPrefs;
  WorkoutPlan? _generatedPlan;
  String? _error;
  Duration? _generationTime;
  Map<String, dynamic>? _debugInfo;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тестовый режим генератора'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showAnalytics(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Форма параметров
            _buildParametersForm(),
            
            const SizedBox(height: 24),
            
            // Кнопка генерации
            ElevatedButton.icon(
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isGenerating ? 'Генерация...' : 'Сгенерировать план'),
              onPressed: _isGenerating ? null : _generatePlan,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            if (_generationTime != null) ...[
              const SizedBox(height: 16),
              Card(
                color: _generationTime!.inMilliseconds < 1000
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        _generationTime!.inMilliseconds < 1000
                            ? Icons.check_circle
                            : Icons.warning,
                        color: _generationTime!.inMilliseconds < 1000
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Время генерации: ${_generationTime!.inMilliseconds} мс',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            if (_error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Ошибка',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_error!),
                    ],
                  ),
                ),
              ),
            ],
            
            if (_generatedPlan != null) ...[
              const SizedBox(height: 24),
              _buildPlanResult(),
            ],
            
            if (_debugInfo != null) ...[
              const SizedBox(height: 24),
              _buildDebugInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParametersForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Параметры тестирования',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Система тренировок
            DropdownButtonFormField<TrainingSystem>(
              decoration: const InputDecoration(
                labelText: 'Система тренировок',
                border: OutlineInputBorder(),
              ),
              value: _testPrefs?.preferredSystem,
              items: TrainingSystem.values.map((system) {
                return DropdownMenuItem(
                  value: system,
                  child: Text(system.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _testPrefs = (_testPrefs ?? _getDefaultPrefs()).copyWith(
                    preferredSystem: value,
                  );
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Уровень опыта
            DropdownButtonFormField<ExperienceLevel>(
              decoration: const InputDecoration(
                labelText: 'Уровень опыта',
                border: OutlineInputBorder(),
              ),
              value: _testPrefs?.experienceLevel ?? ExperienceLevel.beginner,
              items: ExperienceLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _testPrefs = (_testPrefs ?? _getDefaultPrefs()).copyWith(
                    experienceLevel: value,
                  );
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Цель
            DropdownButtonFormField<UserGoal>(
              decoration: const InputDecoration(
                labelText: 'Цель',
                border: OutlineInputBorder(),
              ),
              value: _testPrefs?.goal ?? UserGoal.generalFitness,
              items: UserGoal.values.map((goal) {
                return DropdownMenuItem(
                  value: goal,
                  child: Text(goal.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _testPrefs = (_testPrefs ?? _getDefaultPrefs()).copyWith(
                    goal: value,
                  );
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Дней в неделю
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Дней в неделю',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              initialValue: (_testPrefs?.daysPerWeek ?? 3).toString(),
              onChanged: (value) {
                final days = int.tryParse(value);
                if (days != null) {
                  setState(() {
                    _testPrefs = (_testPrefs ?? _getDefaultPrefs()).copyWith(
                      daysPerWeek: days,
                    );
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanResult() {
    if (_generatedPlan == null) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Результат генерации',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bug_report),
                  onPressed: () => _showDebugInfo(context),
                  tooltip: 'Отладочная информация',
                ),
                IconButton(
                  icon: const Icon(Icons.report_problem),
                  onPressed: () => _reportIssue(context),
                  tooltip: 'Сообщить об ошибке',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text('Название: ${_generatedPlan!.name}'),
            const SizedBox(height: 8),
            Text('Система: ${_generatedPlan!.trainingSystem?.displayName ?? "Не указана"}'),
            const SizedBox(height: 8),
            Text('Тренировок: ${_generatedPlan!.workouts.length}'),
            const SizedBox(height: 8),
            Text('Описание: ${_generatedPlan!.description}'),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Детали тренировок
            const Text(
              'Тренировки:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            ..._generatedPlan!.workouts.asMap().entries.map((entry) {
              final workout = entry.value;
              return ExpansionTile(
                title: Text(workout.name),
                subtitle: Text(
                  workout.isRestDay
                      ? 'День отдыха'
                      : '${workout.exercises.length} упражнений • ${workout.duration} мин',
                ),
                children: workout.isRestDay
                    ? []
                    : workout.exercises.map((exercise) {
                        final exerciseDetails = WorkoutRepository()
                            .getExerciseById(exercise.exerciseId);
                        return ListTile(
                          leading: const Icon(Icons.fitness_center, size: 20),
                          title: Text(exerciseDetails.name.isNotEmpty
                              ? exerciseDetails.name
                              : exercise.exerciseId),
                          subtitle: Text(
                            '${exercise.sets} × ${exercise.reps} • Отдых: ${exercise.restTime}с',
                          ),
                        );
                      }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugInfo() {
    if (_debugInfo == null) return const SizedBox.shrink();
    
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Отладочная информация',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._debugInfo!.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}:',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  UserPreferences _getDefaultPrefs() {
    return UserPreferences(
      goal: UserGoal.generalFitness,
      experienceLevel: ExperienceLevel.beginner,
      trainingLocation: TrainingLocation.gym,
      availableEquipment: [
        Equipment.barbell,
        Equipment.dumbbells,
        Equipment.bench,
      ],
      daysPerWeek: 3,
      sessionDuration: 45,
    );
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isGenerating = true;
      _error = null;
      _generatedPlan = null;
      _debugInfo = null;
      _generationTime = null;
    });

    try {
      final prefs = _testPrefs ?? _getDefaultPrefs();
      final systemRepo = TrainingSystemRepository();
      final workoutRepo = WorkoutRepository();
      final generator = PlanGenerator(systemRepo, workoutRepo);

      final stopwatch = Stopwatch()..start();
      final plan = await generator.generatePlan(prefs);
      stopwatch.stop();

      // Собираем отладочную информацию
      final debugInfo = <String, dynamic>{
        'selectedSystem': prefs.preferredSystem?.displayName ?? 'auto',
        'recommendedSystems': systemRepo
            .getRecommendedSystems(prefs)
            .map((s) => s.system.displayName)
            .toList(),
        'workoutsCount': plan.workouts.length,
        'workoutDays': plan.workouts
            .where((w) => !w.isRestDay)
            .map((w) => {
                  'day': w.dayOfWeek,
                  'focus': w.focus,
                  'exercises': w.exercises.length,
                  'duration': w.duration,
                })
            .toList(),
        'totalExercises': plan.workouts.fold<int>(
          0,
          (sum, w) => sum + w.exercises.length,
        ),
      };

      setState(() {
        _generatedPlan = plan;
        _generationTime = stopwatch.elapsed;
        _debugInfo = debugInfo;
        _isGenerating = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _error = '$e\n\n$stackTrace';
        _isGenerating = false;
        _debugInfo = {
          'error': e.toString(),
          'stackTrace': stackTrace.toString(),
        };
      });
    }
  }

  void _showDebugInfo(BuildContext context) {
    if (_debugInfo == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отладочная информация'),
        content: SingleChildScrollView(
          child: Text(
            _debugInfo!.entries.map((e) => '${e.key}: ${e.value}').join('\n\n'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _reportIssue(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final commentController = TextEditingController();
        
        return AlertDialog(
          title: const Text('Сообщить об ошибке'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Опишите проблему:'),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Введите описание проблемы...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(plannerProvider.notifier).submitPlanFeedback(
                  isPositive: false,
                  comment: commentController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Спасибо за обратную связь!'),
                  ),
                );
              },
              child: const Text('Отправить'),
            ),
          ],
        );
      },
    );
  }

  void _showAnalytics(BuildContext context) {
    final stats = ref.read(plannerProvider.notifier).getAnalyticsStatistics();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статистика аналитики'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Генерация планов:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Всего: ${stats['generationStats']?['totalGenerations'] ?? 0}'),
              Text('Успешно: ${stats['generationStats']?['successfulGenerations'] ?? 0}'),
              Text('Среднее время: ${stats['generationStats']?['averageTimeMs'] ?? 0} мс'),
              const SizedBox(height: 16),
              const Text(
                'Системы тренировок:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(stats['systemStats']?['bySystem'] as Map<String, dynamic>? ?? {})
                  .entries
                  .map((e) => Text('${e.key}: ${e.value}')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}
