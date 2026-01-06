import 'package:flutter/material.dart';
import 'package:fitplan_creator/data/models/workout_exercise.dart';
import 'package:fitplan_creator/data/repositories/workout_repository.dart';
import 'pulsing_exercise_icon.dart';

class DraggableExerciseCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final int index;
  final bool isDragging;
  final VoidCallback onEdit;
  final VoidCallback onReplace;
  final VoidCallback onTap;

  const DraggableExerciseCard({
    super.key,
    required this.exercise,
    required this.index,
    required this.isDragging,
    required this.onEdit,
    required this.onReplace,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final repository = WorkoutRepository();
    final exerciseDetails = repository.getExerciseById(exercise.exerciseId);
    final completedSets = exercise.completedSets.where((c) => c).length;
    final totalSets = exercise.sets;

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDragging 
              ? Colors.grey.shade100 
              : Colors.white,
          border: Border.all(
            color: isDragging 
                ? Colors.blue.shade300 
                : Colors.grey.shade200,
            width: isDragging ? 2 : 1,
          ),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: Colors.blue.withAlpha(76), // 0.3 * 255 ≈ 76
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withAlpha(25), // 0.1 * 255 ≈ 25
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
                onTap: onTap,
                child: PulsingExerciseIcon(
                  exerciseId: exercise.exerciseId,
                  muscleGroup: exerciseDetails.primaryMuscleGroup,
                  size: 40,
                  isActive: !isDragging, // если перетаскиваем, то анимация останавливается
                  showBorder: true,
                  showShadow: false,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      exerciseDetails.id.isNotEmpty 
                          ? exerciseDetails.name 
                          : exercise.exerciseId,
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
                    onPressed: onReplace,
                    tooltip: 'Заменить упражнение',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Редактировать параметры',
                  ),
                  IconButton(
                    icon: const Icon(Icons.drag_handle, size: 20),
                    onPressed: () {},
                    tooltip: 'Перетащить',
                  ),
                ],
              ),
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}