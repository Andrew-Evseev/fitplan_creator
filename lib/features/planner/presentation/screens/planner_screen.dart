import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitplan_creator/core/widgets/custom_button.dart';
import 'package:fitplan_creator/features/planner/providers/planner_provider.dart';
import 'package:fitplan_creator/features/profile/providers/profile_provider.dart';
import 'package:fitplan_creator/features/planner/presentation/widgets/exercise_search_sheet.dart';
import 'package:fitplan_creator/features/planner/presentation/widgets/reorderable_exercise_list.dart';
import 'package:fitplan_creator/features/planner/presentation/widgets/training_system_info_card.dart';
import 'package:fitplan_creator/features/planner/presentation/widgets/muscle_groups_visualization.dart';
import 'package:fitplan_creator/data/models/workout_plan.dart';
import 'package:fitplan_creator/data/models/workout_exercise.dart';
import 'package:fitplan_creator/data/models/exercise.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';
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
          // Кнопка профиля (оставляем видимой, так как это важный элемент)
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              context.go('/profile');
            },
            tooltip: 'Профиль',
          ),
          // Кнопка сохранения плана
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              _savePlan(context, ref, plan);
            },
            tooltip: 'Сохранить план',
          ),
          // Меню с дополнительными действиями
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Дополнительные действия',
            onSelected: (value) {
              switch (value) {
                case 'info':
                  _showPlanInfo(context, plan);
                  break;
                case 'regenerate':
                  _showRegeneratePlanDialog(context, ref);
                  break;
                case 'export':
                  _exportPlan(context, plan);
                  break;
                case 'feedback_positive':
                  ref.read(plannerProvider.notifier).submitPlanFeedback(isPositive: true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Спасибо за отзыв!')),
                  );
                  break;
                case 'feedback_negative':
                  _showFeedbackDialog(context, ref, false);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Информация о плане'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'regenerate',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 12),
                    Text('Перегенерировать план'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 12),
                    Text('Экспорт плана'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'feedback_positive',
                child: Row(
                  children: [
                    Icon(Icons.thumb_up_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Нравится план'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'feedback_negative',
                child: Row(
                  children: [
                    Icon(Icons.thumb_down_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Не нравится план'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: plan.workouts.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                // Прогресс плана
                _buildPlanProgressHeader(context, plan, plannerNotifier),
                
                // Информация о системе тренировок
                if (plan.trainingSystem != null)
                  TrainingSystemInfoCard(
                    system: plan.trainingSystem,
                    plan: plan,
                    progressionTips: _getProgressionTips(plannerNotifier.getSystemStatistics()),
                  ),
                
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
        final plan = ref.read(plannerProvider);
        final userRestrictions = plan.userPreferences?.healthRestrictions
            .where((r) => r != HealthRestriction.none)
            .map((r) => r.displayName)
            .toList() ?? [];
        
        return SingleChildScrollView(
          child: Container(
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
              
              // Видео/изображение если есть
              if (exerciseDetails.videoUrl != null || exerciseDetails.imageUrl != null) ...[
                if (exerciseDetails.videoUrl != null)
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Открыть видео'),
                          onPressed: () {
                            // TODO: Открыть видео в браузере или встроенном плеере
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Видео: ${exerciseDetails.videoUrl}'),
                                action: SnackBarAction(
                                  label: 'Открыть',
                                  onPressed: () {
                                    // Можно использовать url_launcher для открытия ссылки
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                else if (exerciseDetails.imageUrl != null)
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        exerciseDetails.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.image_not_supported, size: 48),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
              
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
              
              // Визуализация задействованных мышц
              if (exerciseDetails.primaryMuscleGroups.isNotEmpty ||
                  exerciseDetails.secondaryMuscleGroups.isNotEmpty)
                MuscleGroupsVisualization(
                  primaryMuscles: exerciseDetails.primaryMuscleGroups,
                  secondaryMuscles: exerciseDetails.secondaryMuscleGroups,
                ),
              if (exerciseDetails.primaryMuscleGroups.isNotEmpty ||
                  exerciseDetails.secondaryMuscleGroups.isNotEmpty)
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
                const SizedBox(height: 20),
              ],
              
              // Противопоказания
              if (exerciseDetails.contraindications.isNotEmpty)
                Builder(
                  builder: (context) {
                    final hasMatchingRestrictions = exerciseDetails.contraindications
                        .any((contra) => userRestrictions.contains(contra));
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: hasMatchingRestrictions 
                                ? Colors.orange[50] 
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: hasMatchingRestrictions 
                                  ? Colors.orange[300]! 
                                  : Colors.grey[300]!,
                              width: hasMatchingRestrictions ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    hasMatchingRestrictions 
                                        ? Icons.warning_amber_rounded 
                                        : Icons.info_outline,
                                    color: hasMatchingRestrictions 
                                        ? Colors.orange[700] 
                                        : Colors.grey[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Противопоказания:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: hasMatchingRestrictions 
                                          ? Colors.orange[900] 
                                          : Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              if (hasMatchingRestrictions) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.orange,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'У вас есть ограничения, которые совпадают с противопоказаниями этого упражнения. '
                                          'Рекомендуется проконсультироваться с врачом перед выполнением.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange[900],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: exerciseDetails.contraindications.map((contra) {
                                  final isUserRestriction = userRestrictions.contains(contra);
                                  return Chip(
                                    label: Text(contra),
                                    backgroundColor: isUserRestriction 
                                        ? Colors.orange[200] 
                                        : Colors.grey[200],
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      color: isUserRestriction 
                                          ? Colors.orange[900] 
                                          : Colors.grey[700],
                                      fontWeight: isUserRestriction 
                                          ? FontWeight.w600 
                                          : FontWeight.normal,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закрыть'),
                ),
              ),
            ],
          ),
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
  void _exportPlan(BuildContext context, WorkoutPlan plan) async {
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
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Копировать'),
            onPressed: () async {
              try {
                await Clipboard.setData(ClipboardData(text: exportText));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('План скопирован в буфер обмена'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка при копировании: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // Сохранение плана
  void _savePlan(BuildContext context, WidgetRef ref, WorkoutPlan plan) {
    ref.read(profileProvider.notifier).savePlan(plan);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('План "${plan.name}" сохранен в профиле'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Открыть профиль',
          textColor: Colors.white,
          onPressed: () {
            context.go('/profile');
          },
        ),
      ),
    );
  }

  // Диалог фидбека
  void _showFeedbackDialog(BuildContext context, WidgetRef ref, bool isPositive) {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPositive ? 'Что вам нравится?' : 'Что можно улучшить?'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(
            hintText: 'Ваш отзыв (необязательно)',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(plannerProvider.notifier).submitPlanFeedback(
                isPositive: isPositive,
                comment: commentController.text.isEmpty ? null : commentController.text,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isPositive
                      ? 'Спасибо за положительный отзыв!'
                      : 'Спасибо за обратную связь!'),
                ),
              );
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  // Пустое состояние
  // Безопасное извлечение progressionTips из статистики
  Map<String, String>? _getProgressionTips(Map<String, dynamic> statistics) {
    try {
      final tips = statistics['progressionTips'];
      if (tips is Map<String, String>) {
        return tips;
      } else if (tips is Map) {
        // Конвертируем Map<dynamic, dynamic> в Map<String, String>
        return tips.map((key, value) => MapEntry(
          key.toString(),
          value.toString(),
        ));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Анимированная иконка
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center_outlined,
                size: 60,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 32),
            
            // Заголовок
            const Text(
              'Создайте свой план тренировок',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Описание
            Text(
              'Пройдите короткую анкету, и мы создадим персональный план тренировок на основе ваших целей, уровня подготовки и доступного оборудования',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            
            // Примеры того, что получит пользователь
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
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.blue[700], size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Что вы получите:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    Icons.calendar_today,
                    'Расписание тренировок на неделю',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.fitness_center,
                    'Подбор упражнений под ваши цели',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.track_changes,
                    'Отслеживание прогресса',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.edit,
                    'Гибкая настройка под себя',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Пример плана (визуализация)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            '1',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Понедельник - Верх тела',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '5 упражнений • 60 мин',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.0,
                    backgroundColor: Colors.grey[200],
                    color: Colors.blue,
                    minHeight: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Пример тренировки из вашего плана',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 40),
            
            // Кнопка создания плана
            CustomButton(
              text: 'Создать план тренировок',
              onPressed: () {
                context.go('/questionnaire');
              },
              fullWidth: true,
              icon: Icons.arrow_forward,
            ),
            const SizedBox(height: 16),
            
            // Дополнительная информация
            TextButton.icon(
              onPressed: () {
                context.push('/onboarding');
              },
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text(
                'Узнать больше о возможностях',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[700], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[900],
            ),
          ),
        ),
      ],
    );
  }
}