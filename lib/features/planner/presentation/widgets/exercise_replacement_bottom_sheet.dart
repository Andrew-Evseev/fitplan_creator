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
    
    // ИСПРАВЛЕНО: получаем equipment как список строк
    final availableEquipmentNames = availableEquipment.map((e) => e.displayName).toList();
    
    final currentExercise = repository.getExerciseById(currentExerciseId);
    final alternativeExercises = repository.findAlternativeExercises(
      currentExerciseId,
      availableEquipmentNames,
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
            )
          else
            Card(
              color: const Color(0xFFFFF3E0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFF57C00)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Упражнение не найдено',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
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
            children: [
              FilterChip(
                label: const Text('По группе мышц'),
                selected: true,
                onSelected: null,
              ),
              FilterChip(
                label: const Text('По оборудованию'),
                selected: true,
                onSelected: null,
              ),
              if (currentExercise.difficulty.name.isNotEmpty)
                FilterChip(
                  label: Text('Сложность: ${_getDifficultyName(currentExercise.difficulty.name)}'),
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
                child: Center(
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
                        if (exercise.primaryMuscleGroups.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getMuscleGroupColor(exercise.primaryMuscleGroups.first),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              exercise.primaryMuscleGroups.first,
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
                            color: _getDifficultyColor(exercise.difficulty.name),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getDifficultyName(exercise.difficulty.name),
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
      'Грудные': const Color(0xFFF44336),
      'Широчайшие': const Color(0xFF4CAF50),
      'Ноги': const Color(0xFF2196F3),
      'Плечи': const Color(0xFFFF9800),
      'Бицепсы': const Color(0xFF9C27B0),
      'Трицепсы': const Color(0xFFE91E63),
      'Прямая мышца живота': const Color(0xFF009688),
      'Квадрицепсы': const Color(0xFF2196F3),
      'Ягодицы': const Color(0xFF673AB7),
      'Задняя поверхность бедра': const Color(0xFF4CAF50),
      'Икры': const Color(0xFF795548),
      'Трапеции': const Color(0xFF607D8B),
      'Предплечья': const Color(0xFF9E9E9E),
      'Шея': const Color(0xFF9C27B0),
      'Верх спины': const Color(0xFF4CAF50),
      'Поясница': const Color(0xFF795548),
      'Ромбовидные': const Color(0xFF4CAF50),
      'Передние дельты': const Color(0xFFFF9800),
      'Средние дельты': const Color(0xFFFF9800),
      'Задние дельты': const Color(0xFFFF9800),
      'Передняя поверхность бедра': const Color(0xFF2196F3),
      'Внутренняя поверхность бедра': const Color(0xFFE91E63),
      'Косые мышцы живота': const Color(0xFF009688),
      'Нижняя часть пресса': const Color(0xFF009688),
      'Внутренняя часть груди': const Color(0xFFF44336),
      'Верхняя часть груди': const Color(0xFFF44336),
      'Нижняя часть груди': const Color(0xFFF44336),
    };
    return colors[muscleGroup] ?? const Color(0xFF9E9E9E);
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