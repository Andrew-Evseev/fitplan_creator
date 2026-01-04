import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitplan_creator/data/models/exercise.dart';
import 'package:fitplan_creator/data/repositories/workout_repository.dart';
import 'package:fitplan_creator/features/planner/providers/planner_provider.dart';
import 'package:fitplan_creator/features/questionnaire/providers/questionnaire_provider.dart';

class ExerciseReplacementBottomSheet extends ConsumerWidget {
  final String workoutId;
  final int exerciseIndex;
  final String currentExerciseId;

  const ExerciseReplacementBottomSheet({
    super.key,
    required this.workoutId,
    required this.exerciseIndex,
    required this.currentExerciseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = WorkoutRepository();
    final availableEquipment = ref.watch(questionnaireProvider).availableEquipment;
    
    final currentExercise = repository.getExerciseById(currentExerciseId);
    final alternativeExercises = repository.findAlternativeExercises(
      currentExerciseId,
      availableEquipment,
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Заменить упражнение',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          if (currentExercise.id.isNotEmpty)
            Card(
              color: const Color(0xFFE3F2FD),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center, color: Color(0xFF1976D2)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentExercise.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Текущее упражнение',
                            style: TextStyle(
                              color: Color(0xFF1976D2),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Альтернативные упражнения',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            children: const [
              FilterChip(
                label: Text('По группе мышц'),
                selected: true,
                onSelected: null,
              ),
              FilterChip(
                label: Text('По оборудованию'),
                selected: true,
                onSelected: null,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: alternativeExercises.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fitness_center_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Нет альтернативных упражнений',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Попробуйте изменить доступное оборудование',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: alternativeExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = alternativeExercises[index];
                      return ExerciseCard(
                        exercise: exercise,
                        onTap: () {
                          ref.read(plannerProvider.notifier).replaceExercise(
                            dayId: workoutId,
                            exerciseIndex: exerciseIndex,
                            newExerciseId: exercise.id,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Упражнение заменено на ${exercise.name}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          
          const SizedBox(height: 8),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: exercise.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          exercise.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.fitness_center,
                                color: Theme.of(context).primaryColor,
                                size: 30,
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.fitness_center,
                          color: Theme.of(context).primaryColor,
                          size: 30,
                        ),
                      ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    Text(
                      exercise.description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getMuscleGroupColor(exercise.primaryMuscleGroup),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getMuscleGroupName(exercise.primaryMuscleGroup),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(exercise.difficulty),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getDifficultyName(exercise.difficulty),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        if (exercise.requiredEquipment.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              exercise.requiredEquipment.length == 1
                                  ? exercise.requiredEquipment.first
                                  : '${exercise.requiredEquipment.length} вида',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Icon(
                Icons.swap_horiz,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getMuscleGroupColor(String muscleGroup) {
    final colors = {
      'chest': const Color(0xFFF44336),
      'back': const Color(0xFF4CAF50),
      'legs': const Color(0xFF2196F3),
      'shoulders': const Color(0xFFFF9800),
      'biceps': const Color(0xFF9C27B0),
      'triceps': const Color(0xFFE91E63),
      'core': const Color(0xFF009688),
      'fullBody': const Color(0xFF3F51B5),
      'calves': const Color(0xFF795548),
      'glutes': const Color(0xFF673AB7),
      'quadriceps': const Color(0xFF2196F3),
      'hamstrings': const Color(0xFF4CAF50),
      'forearms': const Color(0xFF9E9E9E),
      'traps': const Color(0xFF607D8B),
    };
    return colors[muscleGroup] ?? const Color(0xFF9E9E9E);
  }
  
  String _getMuscleGroupName(String muscleGroup) {
    final names = {
      'chest': 'Грудь',
      'back': 'Спина',
      'legs': 'Ноги',
      'shoulders': 'Плечи',
      'biceps': 'Бицепс',
      'triceps': 'Трицепс',
      'core': 'Пресс',
      'fullBody': 'Все тело',
      'calves': 'Икры',
      'glutes': 'Ягодицы',
      'quadriceps': 'Квадрицепс',
      'hamstrings': 'Бицепс бедра',
      'forearms': 'Предплечья',
      'traps': 'Трапеции',
    };
    return names[muscleGroup] ?? muscleGroup;
  }
  
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return const Color(0xFF4CAF50);
      case 'intermediate':
        return const Color(0xFFFF9800);
      case 'advanced':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
  
  String _getDifficultyName(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return 'Начинающий';
      case 'intermediate':
        return 'Средний';
      case 'advanced':
        return 'Продвинутый';
      default:
        return difficulty;
    }
  }
}