import 'package:flutter/material.dart';
import 'package:fitplan_creator/data/models/exercise.dart';
import 'package:fitplan_creator/data/repositories/workout_repository.dart';
import 'pulsing_exercise_icon.dart';

class ExerciseSearchSheet extends StatefulWidget {
  final Function(Exercise) onExerciseSelected;
  final String? currentMuscleGroup;

  const ExerciseSearchSheet({
    super.key,
    required this.onExerciseSelected,
    this.currentMuscleGroup,
  });

  @override
  State<ExerciseSearchSheet> createState() => _ExerciseSearchSheetState();
}

class _ExerciseSearchSheetState extends State<ExerciseSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Exercise> _exercises = [];
  List<Exercise> _filteredExercises = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  void _loadExercises() {
    final repository = WorkoutRepository();
    _exercises = repository.getAllExercises();
    _filteredExercises = _exercises;
    
    // Если передана группа мышц, фильтруем по ней
    if (widget.currentMuscleGroup != null) {
      _filteredExercises = _exercises.where((exercise) =>
        exercise.primaryMuscleGroups.contains(widget.currentMuscleGroup!)
      ).toList();
    }
    
    setState(() {});
  }

  void _filterExercises(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredExercises = _exercises;
      });
      return;
    }

    final filtered = _exercises.where((exercise) {
      return exercise.name.toLowerCase().contains(query.toLowerCase()) ||
             exercise.description.toLowerCase().contains(query.toLowerCase()) ||
             exercise.primaryMuscleGroups.any((muscle) => 
                muscle.toLowerCase().contains(query.toLowerCase()));
    }).toList();

    setState(() {
      _filteredExercises = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Заголовок
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Поиск упражнений',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Поле поиска
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Введите название упражнения...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterExercises('');
                      },
                    ),
                  ),
                  onChanged: _filterExercises,
                ),
              ),

              const SizedBox(height: 8),

              // Информация о количестве
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Найдено: ${_filteredExercises.length} упражнений',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Список упражнений
              Expanded(
                child: _filteredExercises.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Упражнения не найдены',
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Попробуйте изменить поисковый запрос',
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
                        controller: scrollController,
                        itemCount: _filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _filteredExercises[index];
                          return _buildExerciseItem(exercise);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExerciseItem(Exercise exercise) {
    // Используем первую группу мышц
    final primaryMuscle = exercise.primaryMuscleGroups.isNotEmpty 
        ? exercise.primaryMuscleGroups.first 
        : 'Не указана';
    
    // Используем название сложности из enum
    final difficulty = exercise.difficulty.name;
    final difficultyColor = _getDifficultyColor(difficulty);
    
    final equipment = exercise.requiredEquipment.isNotEmpty 
        ? exercise.requiredEquipment.join(', ') 
        : 'Не указано';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: PulsingExerciseIcon(
          exerciseId: exercise.id,
          muscleGroup: primaryMuscle,
          size: 45,
          isActive: true,
          onTap: () {
            // Можно показать увеличенный просмотр
            // ExercisePreviewDialog.show(context: context, exercise: exercise);
          },
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              primaryMuscle,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(_getDifficultyDisplayName(difficulty)),
                  backgroundColor: difficultyColor,
                  labelStyle: const TextStyle(fontSize: 10),
                ),
                const SizedBox(width: 4),
                if (exercise.requiredEquipment.isNotEmpty)
                  Chip(
                    label: Text(
                      equipment,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    backgroundColor: Colors.blue[50],
                    labelStyle: const TextStyle(fontSize: 10),
                  ),
              ],
            ),
          ],
        ),
        onTap: () {
          widget.onExerciseSelected(exercise);
          Navigator.pop(context);
        },
      ),
    );
  }

  Color? _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return Colors.green[50];
      case 'intermediate':
        return Colors.orange[50];
      case 'advanced':
        return Colors.red[50];
      default:
        return Colors.grey[50];
    }
  }

  String _getDifficultyDisplayName(String difficulty) {
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