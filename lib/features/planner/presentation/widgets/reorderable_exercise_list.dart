import 'package:flutter/material.dart';
import 'package:fitplan_creator/data/models/workout_exercise.dart';
import 'package:fitplan_creator/data/repositories/workout_repository.dart';
import 'package:fitplan_creator/data/models/exercise.dart';

class ReorderableExerciseList extends StatefulWidget {
  final List<WorkoutExercise> exercises;
  final String workoutId;
  final Function(int, int) onReorder;
  final Function(int) onEdit;
  final Function(int) onReplace;
  final Function(int) onTap;

  const ReorderableExerciseList({
    super.key,
    required this.exercises,
    required this.workoutId,
    required this.onReorder,
    required this.onEdit,
    required this.onReplace,
    required this.onTap,
  });

  @override
  State<ReorderableExerciseList> createState() => _ReorderableExerciseListState();
}

class _ReorderableExerciseListState extends State<ReorderableExerciseList> {
  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        widget.onReorder(oldIndex, newIndex);
      },
      children: [
        for (int index = 0; index < widget.exercises.length; index++)
          _buildExerciseCard(
            widget.exercises[index],
            index,
            Key('${widget.workoutId}-$index'),
          ),
      ],
    );
  }

  Widget _buildExerciseCard(WorkoutExercise exercise, int index, Key key) {
    final repository = WorkoutRepository();
    final exerciseDetails = repository.getExerciseById(exercise.exerciseId);
    final completedSets = exercise.completedSets.where((c) => c).length;
    final totalSets = exercise.sets;

    // Безопасное получение названия упражнения
    final exerciseName = _getExerciseName(exerciseDetails, exercise.exerciseId);

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25), // Замена withOpacity(0.1) на withAlpha(25)
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Хендлер для перетаскивания
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          
          // Контент карточки
          ListTile(
            leading: GestureDetector(
              onTap: () {
                widget.onTap(index);
              },
              child: CircleAvatar(
                backgroundColor: completedSets == totalSets 
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFE3F2FD),
                child: Icon(
                  completedSets == totalSets 
                      ? Icons.check 
                      : Icons.fitness_center,
                  color: completedSets == totalSets ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    exerciseName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: completedSets == totalSets 
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: completedSets == totalSets ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$completedSets/$totalSets',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: completedSets == totalSets ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${exercise.sets} × ${exercise.reps} повторений • Отдых: ${exercise.restTime} сек',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(exercise.sets, (setIndex) {
                    final isCompleted = setIndex < exercise.completedSets.length 
                        ? exercise.completedSets[setIndex] 
                        : false;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        height: 8,
                        decoration: BoxDecoration(
                          color: isCompleted ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${setIndex + 1}',
                            style: TextStyle(
                              color: isCompleted ? Colors.white : Colors.grey.shade600,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
                    widget.onReplace(index);
                  },
                  tooltip: 'Заменить упражнение',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    widget.onEdit(index);
                  },
                  tooltip: 'Редактировать параметры',
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle,
                    size: 20,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            onTap: () {
              widget.onTap(index);
            },
          ),
        ],
      ),
    );
  }

  // Вспомогательный метод для безопасного получения названия упражнения
  String _getExerciseName(Exercise exercise, String exerciseId) {
    if (exercise.id.isNotEmpty) {
      return exercise.name;
    }
    return exerciseId;
  }
}