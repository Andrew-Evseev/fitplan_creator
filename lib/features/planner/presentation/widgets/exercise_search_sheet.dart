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
        exercise.primaryMuscleGroup == widget.currentMuscleGroup
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
             (exercise.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
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
                child: ListView.builder(
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
    // Используем безопасное получение difficulty
    final difficulty = exercise.difficulty.isNotEmpty ? exercise.difficulty.toLowerCase() : 'легкий';
    final difficultyColor = _getDifficultyColor(difficulty);
    
    final muscleGroup = exercise.primaryMuscleGroup;
    final equipment = exercise.requiredEquipment?.join(', ') ?? 'Не указано';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: PulsingExerciseIcon(
          exerciseId: exercise.id,
          muscleGroup: muscleGroup,
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
              muscleGroup,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(difficulty),
                  backgroundColor: difficultyColor,
                  labelStyle: const TextStyle(fontSize: 10),
                ),
                const SizedBox(width: 4),
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
      case 'начинающий':
        return Colors.green[50];
      case 'intermediate':
      case 'средний':
        return Colors.orange[50];
      case 'advanced':
      case 'продвинутый':
        return Colors.red[50];
      default:
        return Colors.grey[50];
    }
  }
}