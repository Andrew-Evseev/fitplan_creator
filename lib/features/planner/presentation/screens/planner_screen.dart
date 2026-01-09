import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitplan_creator/core/widgets/custom_button.dart';
import 'package:fitplan_creator/features/planner/providers/planner_provider.dart';
import 'package:fitplan_creator/features/profile/providers/profile_provider.dart';
import 'package:fitplan_creator/features/planner/presentation/widgets/exercise_search_sheet.dart';
import 'package:fitplan_creator/features/planner/presentation/widgets/reorderable_exercise_list.dart';
import 'package:fitplan_creator/data/models/workout_plan.dart';
import 'package:fitplan_creator/data/models/workout_exercise.dart';
import 'package:fitplan_creator/data/models/exercise.dart'; // ← ДОБАВЛЕН ИМПОРТ
import 'package:fitplan_creator/data/repositories/workout_repository.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  final Set<int> _expandedWorkouts = {};

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(plannerProvider);
    final plannerNotifier = ref.read(plannerProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ваш план тренировок'),
        actions: [
          // Кнопка профиля
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              context.go('/profile');
            },
            tooltip: 'Профиль',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showPlanInfo(context, plan);
            },
            tooltip: 'Информация о плане',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _showRegeneratePlanDialog(context, ref);
            },
            tooltip: 'Перегенерировать план',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              _exportPlan(context, plan);
            },
            tooltip: 'Экспорт плана',
          ),
        ],
      ),
      body: plan.workouts.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                // Прогресс плана
                _buildPlanProgressHeader(context, plan, plannerNotifier),
                
                // Список тренировок
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: plan.workouts.length,
                    itemBuilder: (context, index) {
                      final workout = plan.workouts[index];
                      return _buildWorkoutCard(
                        context, 
                        ref, 
                        workout, 
                        index,
                        isExpanded: _expandedWorkouts.contains(index),
                        onExpansionChanged: (expanded) {
                          setState(() {
                            if (expanded) {
                              _expandedWorkouts.add(index);
                            } else {
                              _expandedWorkouts.remove(index);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // Заголовок с прогрессом плана
  Widget _buildPlanProgressHeader(BuildContext context, WorkoutPlan plan, PlannerNotifier plannerNotifier) {
    final progress = plannerNotifier.getProgress();
    final completedWorkouts = plan.workouts.where((w) => w.completed).length;
    final totalWorkouts = plan.workouts.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(12),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  Text(
                    '$completedWorkouts/$totalWorkouts',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            color: const Color(0xFF2196F3),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  // Карточка тренировки
  Widget _buildWorkoutCard(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
    int index, {
    required bool isExpanded,
    required void Function(bool) onExpansionChanged,
  }) {
    final dayNames = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
    final dayName = workout.dayOfWeek >= 1 && workout.dayOfWeek <= 7 
        ? dayNames[workout.dayOfWeek - 1] 
        : 'День ${workout.dayOfWeek}';
    
    final completedSetsCount = workout.exercises.expand((e) => e.completedSets).where((c) => c).length;
    final totalSetsCount = workout.exercises.fold(0, (sum, e) => sum + e.sets);
    final progress = totalSetsCount > 0 ? completedSetsCount / totalSetsCount : 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpansionChanged,
        leading: CircleAvatar(
          backgroundColor: workout.completed 
              ? const Color(0xFF4CAF50)
              : _getDayColor(workout.dayOfWeek),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          workout.name.isNotEmpty ? workout.name : dayName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${workout.exercises.length} упражнений • ${workout.duration} мин',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: workout.completed ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!workout.completed)
              IconButton(
                icon: const Icon(Icons.restart_alt, size: 20),
                onPressed: () {
                  _resetWorkoutCompletion(context, ref, workout.id);
                },
                tooltip: 'Сбросить выполнение',
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: workout.completed 
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: workout.completed ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                  width: 1,
                ),
              ),
              child: Text(
                workout.completed ? 'Выполнено' : 'К выполнению',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: workout.completed ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                ),
              ),
            ),
          ],
        ),
        children: [
          // Drag-and-drop список упражнений
          Container(
            constraints: const BoxConstraints(
              maxHeight: 400.0, // Ограничиваем максимальную высоту
            ),
            child: ReorderableExerciseList(
              exercises: workout.exercises,
              workoutId: workout.id,
              onReorder: (oldIndex, newIndex) {
                // Вызываем метод в провайдере для перестановки упражнений
                ref.read(plannerProvider.notifier).reorderExercise(
                  workoutId: workout.id,
                  oldIndex: oldIndex,
                  newIndex: newIndex,
                );
              },
              onEdit: (exerciseIndex) {
                _editExerciseParameters(
                  context, 
                  ref, 
                  workout.id, 
                  exerciseIndex, 
                  workout.exercises[exerciseIndex]
                );
              },
              onReplace: (exerciseIndex) {
                _replaceExercise(
                  context, 
                  ref, 
                  workout.id, 
                  exerciseIndex, 
                  workout.exercises[exerciseIndex].exerciseId
                );
              },
              onTap: (exerciseIndex) {
                _showExerciseDetails(
                  context, 
                  ref, 
                  workout.exercises[exerciseIndex]
                );
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text('Завершить тренировку'),
                  onPressed: () {
                    _completeWorkout(context, ref, workout.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: const Text('Сбросить'),
                  onPressed: () {
                    _resetWorkoutCompletion(context, ref, workout.id);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Цвет дня недели
  Color _getDayColor(int day) {
    final colors = [
      const Color(0xFFEF5350),  // Понедельник
      const Color(0xFFFFA726),  // Вторник
      const Color(0xFFFFEE58),  // Среда
      const Color(0xFF66BB6A),  // Четверг
      const Color(0xFF42A5F5),  // Пятница
      const Color(0xFF5C6BC0),  // Суббота
      const Color(0xFFAB47BC),  // Воскресенье
    ];
    return day >= 1 && day <= 7 ? colors[day - 1] : Colors.grey.shade400;
  }

  // Показать диалог перегенерации плана
  void _showRegeneratePlanDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Перегенерировать план'),
        content: const Text('Это создаст новый план на основе ваших предпочтений. Текущий прогресс будет потерян. Продолжить?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(plannerProvider.notifier).resetPlan();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('План перегенерирован'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Перегенерировать'),
          ),
        ],
      ),
    );
  }

  // Завершить тренировку (обновленная версия с интеграцией профиля)
  void _completeWorkout(BuildContext context, WidgetRef ref, String workoutId) {
    final plan = ref.read(plannerProvider);
    final workoutIndex = plan.workouts.indexWhere((w) => w.id == workoutId);
    if (workoutIndex == -1) return;
    
    final workout = plan.workouts[workoutIndex];
    
    // Собираем статистику по группам мышц для профиля
    final repository = WorkoutRepository();
    final muscleGroups = <String, int>{};
    
    for (int i = 0; i < workout.exercises.length; i++) {
      final exercise = workout.exercises[i];
      
      // Обновляем выполнение каждого подхода
      for (int j = 0; j < exercise.sets; j++) {
        ref.read(plannerProvider.notifier).updateSetCompletion(
          dayId: workoutId,
          exerciseIndex: i,
          setIndex: j,
          completed: true,
        );
      }
      
      // Собираем статистику по группам мышц
      final exerciseDetails = repository.getExerciseById(exercise.exerciseId);
      // ИСПРАВЛЕНИЕ: используем безопасный геттер
      final primaryMuscleGroup = _getPrimaryMuscleGroup(exerciseDetails);
      if (primaryMuscleGroup.isNotEmpty) {
        muscleGroups[primaryMuscleGroup] = (muscleGroups[primaryMuscleGroup] ?? 0) + 1;
      }
    }
    
    // Обновляем статистику в профиле
    ref.read(profileProvider.notifier).updateStatsAfterWorkout(
      duration: workout.duration,
      exercisesCount: workout.exercises.length,
      muscleGroups: muscleGroups,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Тренировка "${workout.name}" завершена!'),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Вспомогательный метод для безопасного получения группы мышц
  String _getPrimaryMuscleGroup(Exercise exercise) {
    if (exercise.primaryMuscleGroups.isNotEmpty) {
      return exercise.primaryMuscleGroups.first;
    }
    return '';
  }

  // Сбросить выполнение тренировки
  void _resetWorkoutCompletion(BuildContext context, WidgetRef ref, String workoutId) {
    ref.read(plannerProvider.notifier).resetWorkoutCompletion(workoutId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Выполнение тренировки сброшено'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Замена упражнения
  void _replaceExercise(
    BuildContext context,
    WidgetRef ref,
    String workoutId,
    int exerciseIndex,
    String currentExerciseId,
  ) {
    // Получаем текущее упражнение для определения группы мышц
    final repository = WorkoutRepository();
    final currentExercise = repository.getExerciseById(currentExerciseId);
    // ИСПРАВЛЕНИЕ: используем безопасный геттер
    final currentMuscleGroup = _getPrimaryMuscleGroup(currentExercise);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExerciseSearchSheet(
        onExerciseSelected: (exercise) {
          ref.read(plannerProvider.notifier).replaceExercise(
            dayId: workoutId,
            exerciseIndex: exerciseIndex,
            newExerciseId: exercise.id,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Упражнение заменено на ${exercise.name}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        currentMuscleGroup: currentMuscleGroup.isNotEmpty ? currentMuscleGroup : null,
      ),
    );
  }

  // Редактирование параметров упражнения
  void _editExerciseParameters(
    BuildContext context,
    WidgetRef ref,
    String workoutId,
    int exerciseIndex,
    WorkoutExercise exercise,
  ) {
    final setsController = TextEditingController(text: exercise.sets.toString());
    final repsController = TextEditingController(text: exercise.reps.toString());
    final restController = TextEditingController(text: exercise.restTime.toString());
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Редактировать параметры'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: setsController,
                decoration: const InputDecoration(
                  labelText: 'Подходы',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: repsController,
                decoration: const InputDecoration(
                  labelText: 'Повторения',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: restController,
                decoration: const InputDecoration(
                  labelText: 'Отдых (секунды)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
                final newSets = int.tryParse(setsController.text) ?? exercise.sets;
                final newReps = int.tryParse(repsController.text) ?? exercise.reps;
                final newRest = int.tryParse(restController.text) ?? exercise.restTime;
                
                ref.read(plannerProvider.notifier).updateExerciseParameters(
                  workoutId: workoutId,
                  exerciseIndex: exerciseIndex,
                  sets: newSets,
                  reps: newReps,
                  restTime: newRest,
                );
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Параметры изменены: $newSets подходов, $newReps повторений, отдых $newRest сек'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  // Детали упражнения
  void _showExerciseDetails(BuildContext context, WidgetRef ref, WorkoutExercise exercise) {
    final exerciseDetails = ref.read(plannerProvider.notifier).getExerciseById(exercise.exerciseId);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Center(
                child: Text(
                  exerciseDetails.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 16),
              
              if (exerciseDetails.description.isNotEmpty)
                Text(
                  exerciseDetails.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              
              const SizedBox(height: 20),
              
              const Text(
                'Параметры выполнения:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailCard('Подходы', '${exercise.sets}', Icons.repeat),
                  _buildDetailCard('Повторения', '${exercise.reps}', Icons.format_list_numbered),
                  _buildDetailCard('Отдых', '${exercise.restTime} сек', Icons.timer),
                ],
              ),
              
              const SizedBox(height: 20),
              
              if (exerciseDetails.instructions.isNotEmpty) ...[
                const Text(
                  'Техника выполнения:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  exerciseDetails.instructions,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закрыть'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF2196F3),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }

  // Информация о плане
  void _showPlanInfo(BuildContext context, WorkoutPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Информация о плане'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Название: ${plan.name}'),
              const SizedBox(height: 8),
              Text('Описание: ${plan.description}'),
              const SizedBox(height: 8),
              Text('Создан: ${plan.createdAt.toLocal().toString().split(' ')[0]}'),
              const SizedBox(height: 8),
              Text('Тренировок в плане: ${plan.workouts.length}'),
              const SizedBox(height: 16),
              if (plan.userPreferences != null) ...[
                const Text(
                  'Настройки пользователя:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Цель: ${plan.userPreferences!.goal?.displayName ?? 'Не указано'}'),
                Text('Уровень: ${plan.userPreferences!.experienceLevel?.displayName ?? 'Не указано'}'),
                Text('Дней в неделю: ${plan.userPreferences!.daysPerWeek ?? 'Не указано'}'),
                Text('Длительность: ${plan.userPreferences!.sessionDuration ?? 'Не указано'} мин'),
              ],
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

  // Экспорт плана
  void _exportPlan(BuildContext context, WorkoutPlan plan) {
    final exportText = ref.read(plannerProvider.notifier).exportPlanToText();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Экспорт плана'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(exportText),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Реализовать копирование в буфер обмена
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Скопировано в буфер обмена'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Копировать'),
          ),
        ],
      ),
    );
  }

  // Пустое состояние
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fitness_center_outlined,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              'План тренировок не сгенерирован',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Пройдите анкету, чтобы создать персональный план тренировок',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Создать план',
              onPressed: () {
                context.go('/questionnaire');
              },
            ),
          ],
        ),
      ),
    );
  }
}