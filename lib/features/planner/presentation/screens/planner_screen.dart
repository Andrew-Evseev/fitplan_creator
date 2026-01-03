import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitplan_creator/core/widgets/custom_button.dart';
import 'package:fitplan_creator/features/planner/providers/planner_provider.dart';
import 'package:fitplan_creator/data/models/workout_plan.dart';
import 'package:fitplan_creator/data/models/workout_exercise.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(plannerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ваш план тренировок'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: () {
              context.go('/welcome');
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              _exportPlan(context, plan);
            },
          ),
        ],
      ),
      body: plan.workouts.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plan.workouts.length,
              itemBuilder: (context, index) {
                final workout = plan.workouts[index];
                return _buildWorkoutCard(context, ref, workout, index);
              },
            ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, WidgetRef ref, Workout workout, int index) {
    final dayNames = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
    final dayName = workout.dayOfWeek >= 1 && workout.dayOfWeek <= 7 
        ? dayNames[workout.dayOfWeek - 1] 
        : 'День ${workout.dayOfWeek}';
    
    final completedSetsCount = workout.exercises.expand((e) => e.completedSets).where((c) => c).length;
    final totalSetsCount = workout.exercises.fold(0, (sum, e) => sum + e.sets);
    final progress = totalSetsCount > 0 ? completedSetsCount / totalSetsCount : 0.0; // ИСПРАВЛЕНО: 0 -> 0.0
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: workout.completed ? Colors.green : _getDayColor(workout.dayOfWeek),
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          workout.name.isNotEmpty ? workout.name : dayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${workout.exercises.length} упражнений • ${workout.duration} мин'),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              color: workout.completed ? Colors.green : Colors.blue,
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            workout.completed ? Icons.check_circle : Icons.circle_outlined,
            color: workout.completed ? Colors.green : Colors.grey,
          ),
          onPressed: () {
            _toggleWorkoutCompletion(context, ref, index, workout);
          },
        ),
        children: [
          ...workout.exercises.asMap().entries.map((entry) {
            final exerciseIndex = entry.key;
            final exercise = entry.value;
            return _buildExerciseTile(context, ref, workout, index, exercise, exerciseIndex);
          }).toList(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить упражнение'),
                  onPressed: () {
                    _addExercise(context, ref, index);
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Перемешать'),
                  onPressed: () {
                    _shuffleWorkout(context, ref, index);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(BuildContext context, WidgetRef ref, Workout workout, int workoutIndex, WorkoutExercise exercise, int exerciseIndex) {
    final completedSets = exercise.completedSets.where((c) => c).length;
    final totalSets = exercise.sets;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: completedSets == totalSets ? Colors.green : Colors.blue[50],
        child: Icon(
          completedSets == totalSets ? Icons.check : Icons.fitness_center,
          color: completedSets == totalSets ? Colors.white : Colors.blue[700],
        ),
      ),
      title: Text(
        _getExerciseName(exercise.exerciseId),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${exercise.sets} x ${exercise.reps} • Отдых: ${exercise.restTime} сек'),
          const SizedBox(height: 4),
          Row(
            children: List.generate(exercise.sets, (setIndex) {
              final isCompleted = setIndex < exercise.completedSets.length 
                  ? exercise.completedSets[setIndex] 
                  : false;
              return Container(
                width: 20,
                height: 8,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, size: 20),
            onPressed: () {
              _replaceExercise(context, ref, workoutIndex, exerciseIndex);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () {
              _editExercise(context, ref, workoutIndex, exerciseIndex, exercise);
            },
          ),
        ],
      ),
      onTap: () {
        _showExerciseDetails(context, exercise);
      },
      onLongPress: () {
        _toggleExerciseSet(context, ref, workoutIndex, exerciseIndex);
      },
    );
  }

  String _getExerciseName(String exerciseId) {
    final exerciseNames = {
      'bench_press': 'Жим штанги лежа',
      'squats': 'Приседания',
      'pull_ups': 'Подтягивания',
      'push_ups': 'Отжимания',
      'deadlift': 'Становая тяга',
      'bicep_curls': 'Сгибания рук с гантелями',
      'plank': 'Планка',
    };
    
    return exerciseNames[exerciseId] ?? exerciseId;
  }

  Color _getDayColor(int day) {
    final colors = [
      Colors.red,      // 1 - Понедельник
      Colors.orange,   // 2 - Вторник
      Colors.yellow[700]!, // 3 - Среда
      Colors.green,    // 4 - Четверг
      Colors.blue,     // 5 - Пятница
      Colors.indigo,   // 6 - Суббота
      Colors.purple,   // 7 - Воскресенье
    ];
    return day >= 1 && day <= 7 ? colors[day - 1] : Colors.grey;
  }

  void _toggleWorkoutCompletion(BuildContext context, WidgetRef ref, int workoutIndex, Workout workout) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Завершение тренировки'),
          content: Text('Отметить тренировку "${workout.name}" как завершенную?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Реализовать отметку тренировки как завершенной
                Navigator.pop(context);
              },
              child: const Text('Завершить'),
            ),
          ],
        );
      },
    );
  }

  void _toggleExerciseSet(BuildContext context, WidgetRef ref, int workoutIndex, int exerciseIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Отметить подход'),
          content: const Text('Выберите подход для отметки:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
  }

  void _showExerciseDetails(BuildContext context, WorkoutExercise exercise) {
    final exerciseName = _getExerciseName(exercise.exerciseId);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  exerciseName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Параметры:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Подходы: ${exercise.sets}'),
              Text('Повторения: ${exercise.reps}'),
              Text('Отдых между подходами: ${exercise.restTime} сек'),
              
              const SizedBox(height: 16),
              const Text(
                'Статус подходов:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: exercise.completedSets.asMap().entries.map((entry) {
                  final setIndex = entry.key;
                  final isCompleted = entry.value;
                  return Chip(
                    label: Text('${setIndex + 1} подход'),
                    backgroundColor: isCompleted ? Colors.green[100] : Colors.grey[200],
                    labelStyle: TextStyle(
                      color: isCompleted ? Colors.green[800] : Colors.grey[600],
                    ),
                  );
                }).toList(),
              ),
              
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

  void _replaceExercise(BuildContext context, WidgetRef ref, int workoutIndex, int exerciseIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Замена упражнения'),
          content: const Text('Функционал замены упражнений будет реализован в ближайшее время.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _editExercise(BuildContext context, WidgetRef ref, int workoutIndex, int exerciseIndex, WorkoutExercise exercise) {
    final setsController = TextEditingController(text: exercise.sets.toString());
    final repsController = TextEditingController(text: exercise.reps.toString());
    final restController = TextEditingController(text: exercise.restTime.toString());
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Редактировать упражнение'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: setsController,
                decoration: const InputDecoration(labelText: 'Подходы'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: repsController,
                decoration: const InputDecoration(labelText: 'Повторения'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: restController,
                decoration: const InputDecoration(labelText: 'Отдых (сек)'),
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
                // TODO: Реализовать обновление упражнения
                Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  void _addExercise(BuildContext context, WidgetRef ref, int workoutIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавление упражнения'),
          content: const Text('Функционал добавления упражнений будет реализован в ближайшее время.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _shuffleWorkout(BuildContext context, WidgetRef ref, int workoutIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Перемешать упражнения'),
          content: const Text('Функционал перемешивания будет реализован в ближайшее время.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _exportPlan(BuildContext context, WorkoutPlan plan) {
    final buffer = StringBuffer();
    buffer.writeln('ПЛАН ТРЕНИРОВОК');
    buffer.writeln('===============');
    buffer.writeln();
    
    for (final workout in plan.workouts) {
      final dayNames = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
      final dayName = workout.dayOfWeek >= 1 && workout.dayOfWeek <= 7 
          ? dayNames[workout.dayOfWeek - 1] 
          : 'День ${workout.dayOfWeek}';
      
      buffer.writeln('$dayName: ${workout.name}');
      buffer.writeln('${workout.duration} минут, ${workout.exercises.length} упражнений');
      buffer.writeln();
      
      for (final exercise in workout.exercises) {
        buffer.writeln('  - ${_getExerciseName(exercise.exerciseId)}');
        buffer.writeln('    ${exercise.sets} x ${exercise.reps} повторений, отдых ${exercise.restTime} сек');
      }
      
      buffer.writeln();
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Экспорт плана'),
          content: SingleChildScrollView(
            child: SelectableText(buffer.toString()),
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
              },
              child: const Text('Копировать'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'План тренировок не сгенерирован',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Пройдите анкету, чтобы создать персональный план тренировок',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Создать план',
            onPressed: () {
              context.go('/questionnaire');
            },
          ),
        ],
      ),
    );
  }
}
