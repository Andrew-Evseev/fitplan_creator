// lib/features/planner/presentation/widgets/exercise_preview_dialog.dart
import 'package:flutter/material.dart';
import 'package:fitplan_creator/data/models/exercise.dart';
import '../../utils/exercise_icon_utils.dart';
import 'pulsing_exercise_icon.dart';

class ExercisePreviewDialog extends StatelessWidget {
  final Exercise exercise;
  
  const ExercisePreviewDialog({
    super.key,
    required this.exercise,
  });

  static Future<void> show({
    required BuildContext context,
    required Exercise exercise,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => ExercisePreviewDialog(exercise: exercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Используем первую группу мышц для получения цвета и названия
    final primaryMuscle = exercise.primaryMuscleGroups.isNotEmpty 
        ? exercise.primaryMuscleGroups.first 
        : '';
    final color = ExerciseIconUtils.getMuscleGroupColor(primaryMuscle);
    final muscleGroupName = ExerciseIconUtils.getMuscleGroupName(primaryMuscle);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51), // 0.2 * 255 ≈ 51
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Анимированная иконка
            PulsingExerciseIcon(
              exerciseId: exercise.id,
              muscleGroup: primaryMuscle,
              size: 120,
              isActive: true,
              showBorder: true,
              showShadow: true,
              useGradient: true,
            ),
            
            const SizedBox(height: 20),
            
            // Название упражнения
            Text(
              exercise.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 10),
            
            // Группа мышц
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fitness_center,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  muscleGroupName,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Детали упражнения
            if (exercise.description.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  exercise.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Кнопка закрытия
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ПОНЯТНО',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}