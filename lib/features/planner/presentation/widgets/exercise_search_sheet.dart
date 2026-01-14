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
  String? _selectedMuscleGroup;
  String? _selectedEquipment;
  final Set<String> _availableMuscleGroups = {};
  final Set<String> _availableEquipment = {};

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  void _loadExercises() {
    final repository = WorkoutRepository();
    _exercises = repository.getAllExercises();
    
    // Собираем доступные группы мышц и оборудование
    for (final exercise in _exercises) {
      _availableMuscleGroups.addAll(exercise.primaryMuscleGroups);
      _availableEquipment.addAll(exercise.requiredEquipment);
    }
    
    _filteredExercises = _exercises;
    
    // Если передана группа мышц, фильтруем по ней
    if (widget.currentMuscleGroup != null) {
      _selectedMuscleGroup = widget.currentMuscleGroup;
      _applyFilters();
    }
    
    setState(() {});
  }

  void _applyFilters() {
    var filtered = List<Exercise>.from(_exercises);
    
    // Фильтр по поисковому запросу
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((exercise) {
        return exercise.name.toLowerCase().contains(query) ||
               exercise.description.toLowerCase().contains(query) ||
               exercise.primaryMuscleGroups.any((muscle) => 
                  muscle.toLowerCase().contains(query));
      }).toList();
    }
    
    // Фильтр по группе мышц
    if (_selectedMuscleGroup != null) {
      filtered = filtered.where((exercise) =>
        exercise.primaryMuscleGroups.contains(_selectedMuscleGroup!)
      ).toList();
    }
    
    // Фильтр по оборудованию
    if (_selectedEquipment != null) {
      filtered = filtered.where((exercise) {
        if (_selectedEquipment == 'Без оборудования') {
          return exercise.isBodyweight || exercise.requiredEquipment.isEmpty;
        }
        return exercise.requiredEquipment.contains(_selectedEquipment!);
      }).toList();
    }
    
    setState(() {
      _filteredExercises = filtered;
    });
  }

  void _filterExercises(String query) {
    _applyFilters();
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

              // Фильтры
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Фильтр по группе мышц
                    if (_availableMuscleGroups.isNotEmpty)
                      DropdownButton<String>(
                        value: _selectedMuscleGroup,
                        hint: const Text('Группа мышц'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Все группы'),
                          ),
                          ..._availableMuscleGroups.map((group) => DropdownMenuItem<String>(
                            value: group,
                            child: Text(group),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedMuscleGroup = value;
                            _applyFilters();
                          });
                        },
                      ),
                    
                    const SizedBox(width: 8),
                    
                    // Фильтр по оборудованию
                    DropdownButton<String>(
                      value: _selectedEquipment,
                      hint: const Text('Оборудование'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Все'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'Без оборудования',
                          child: Text('Без оборудования'),
                        ),
                        ..._availableEquipment.map((eq) => DropdownMenuItem<String>(
                          value: eq,
                          child: Text(eq),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedEquipment = value;
                          _applyFilters();
                        });
                      },
                    ),
                    
                    // Кнопка сброса фильтров
                    if (_selectedMuscleGroup != null || _selectedEquipment != null)
                      TextButton.icon(
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Сбросить'),
                        onPressed: () {
                          setState(() {
                            _selectedMuscleGroup = null;
                            _selectedEquipment = null;
                            _applyFilters();
                          });
                        },
                      ),
                  ],
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
        leading: GestureDetector(
          onTap: () => _showExercisePreview(exercise),
          child: PulsingExerciseIcon(
            exerciseId: exercise.id,
            muscleGroup: primaryMuscle,
            size: 45,
            isActive: true,
            onTap: () => _showExercisePreview(exercise),
          ),
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
        trailing: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showExercisePreview(exercise),
          tooltip: 'Просмотр деталей',
        ),
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

  void _showExercisePreview(Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
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
            Row(
              children: [
                PulsingExerciseIcon(
                  exerciseId: exercise.id,
                  muscleGroup: exercise.primaryMuscleGroups.isNotEmpty
                      ? exercise.primaryMuscleGroups.first
                      : '',
                  size: 60,
                  isActive: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (exercise.primaryMuscleGroups.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: exercise.primaryMuscleGroups.map((muscle) {
                            return Chip(
                              label: Text(muscle),
                              labelStyle: const TextStyle(fontSize: 12),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (exercise.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                exercise.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
            if (exercise.instructions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Техника выполнения:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exercise.instructions,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (exercise.requiredEquipment.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.fitness_center, size: 16),
                    label: Text('Оборудование: ${exercise.requiredEquipment.join(', ')}'),
                  ),
                Chip(
                  avatar: Icon(
                    Icons.signal_cellular_alt,
                    size: 16,
                    color: _getDifficultyColor(exercise.difficulty.name),
                  ),
                  label: Text(_getDifficultyDisplayName(exercise.difficulty.name)),
                ),
                if (exercise.isBodyweight)
                  const Chip(
                    avatar: Icon(Icons.person, size: 16),
                    label: Text('С весом тела'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onExerciseSelected(exercise);
                  Navigator.pop(context); // Закрываем превью
                  Navigator.pop(context); // Закрываем поиск
                },
                child: const Text('Выбрать это упражнение'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}