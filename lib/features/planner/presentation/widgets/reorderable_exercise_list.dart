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

class _ReorderableExerciseListState extends State<ReorderableExerciseList>
    with TickerProviderStateMixin {
  final Map<int, AnimationController> _animationControllers = {};
  final Map<int, Animation<double>> _scaleAnimations = {};

  @override
  void initState() {
    super.initState();
    // Создаем анимации для каждого упражнения
    for (int i = 0; i < widget.exercises.length; i++) {
      _createAnimation(i);
    }
  }

  @override
  void didUpdateWidget(ReorderableExerciseList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем анимации при изменении количества упражнений
    if (widget.exercises.length != oldWidget.exercises.length) {
      for (int i = oldWidget.exercises.length; i < widget.exercises.length; i++) {
        _createAnimation(i);
      }
    }
  }

  void _createAnimation(int index) {
    _animationControllers[index] = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimations[index] = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationControllers[index]!,
        curve: Curves.easeOut,
      ),
    );
    _animationControllers[index]!.forward();
  }

  @override
  void dispose() {
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Разделяем упражнения на группы
    final warmupExercises = <WorkoutExercise>[];
    final mainExercises = <WorkoutExercise>[];
    final cooldownExercises = <WorkoutExercise>[];
    
    final repository = WorkoutRepository();
    for (final exercise in widget.exercises) {
      final exerciseDetails = repository.getExerciseById(exercise.exerciseId);
      if (exerciseDetails.id.isNotEmpty) {
        if (exerciseDetails.isWarmup) {
          warmupExercises.add(exercise);
        } else if (exerciseDetails.isCooldown) {
          cooldownExercises.add(exercise);
        } else {
          mainExercises.add(exercise);
        }
      } else {
        // Если упражнение не найдено, проверяем по ID
        if (exercise.exerciseId.startsWith('warmup_')) {
          warmupExercises.add(exercise);
        } else if (exercise.exerciseId.startsWith('cooldown_')) {
          cooldownExercises.add(exercise);
        } else {
          mainExercises.add(exercise);
        }
      }
    }
    
    // Строим список с заголовками групп
    final children = <Widget>[];
    
    // Разминка
    if (warmupExercises.isNotEmpty) {
      children.add(_buildSectionHeader('Разминка', warmupExercises.length));
      for (int i = 0; i < warmupExercises.length; i++) {
        final exerciseIndex = widget.exercises.indexOf(warmupExercises[i]);
        children.add(_buildExerciseCard(
          warmupExercises[i],
          exerciseIndex,
          key: Key('${widget.workoutId}-warmup-$exerciseIndex'),
        ));
      }
    }
    
    // Основные упражнения
    if (mainExercises.isNotEmpty) {
      children.add(_buildSectionHeader('Основные упражнения', mainExercises.length));
      for (int i = 0; i < mainExercises.length; i++) {
        final exerciseIndex = widget.exercises.indexOf(mainExercises[i]);
        children.add(_buildExerciseCard(
          mainExercises[i],
          exerciseIndex,
          key: Key('${widget.workoutId}-main-$exerciseIndex'),
        ));
      }
    }
    
    // Заминка
    if (cooldownExercises.isNotEmpty) {
      children.add(_buildSectionHeader('Заминка', cooldownExercises.length));
      for (int i = 0; i < cooldownExercises.length; i++) {
        final exerciseIndex = widget.exercises.indexOf(cooldownExercises[i]);
        children.add(_buildExerciseCard(
          cooldownExercises[i],
          exerciseIndex,
          key: Key('${widget.workoutId}-cooldown-$exerciseIndex'),
        ));
      }
    }
    
    // Используем Column вместо ReorderableListView для поддержки заголовков
    // Но сохраняем возможность переупорядочивания внутри каждой секции
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: children,
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, int count) {
    return Container(
      key: ValueKey('header-$title'),
      margin: const EdgeInsets.only(top: 16, bottom: 8, left: 8, right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            title == 'Разминка' ? Icons.wb_sunny_outlined :
            title == 'Заминка' ? Icons.wb_twilight_outlined :
            Icons.fitness_center,
            size: 18,
            color: title == 'Разминка' ? Colors.orange :
                   title == 'Заминка' ? Colors.blue :
                   Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const Spacer(),
          Text(
            '$count ${_getExerciseWord(count)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getExerciseWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'упражнение';
    if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return 'упражнения';
    }
    return 'упражнений';
  }

  Widget _buildExerciseCard(WorkoutExercise exercise, int index, {required Key key}) {
    final repository = WorkoutRepository();
    final exerciseDetails = repository.getExerciseById(exercise.exerciseId);
    final completedSets = exercise.completedSets.where((c) => c).length;
    final totalSets = exercise.sets;

    // Безопасное получение названия упражнения
    final exerciseName = _getExerciseName(exerciseDetails, exercise.exerciseId);

    final animation = _scaleAnimations[index] ?? const AlwaysStoppedAnimation(1.0);
    
    return ScaleTransition(
      key: key,
      scale: animation,
      child: Container(
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
              color: Colors.grey.withAlpha(25),
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
                    completedSets == totalSets ? Icons.check : Icons.fitness_center,
                    color: completedSets == totalSets
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF2196F3),
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
                        color: completedSets == totalSets
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF2196F3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$completedSets/$totalSets',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: completedSets == totalSets
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF2196F3),
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
                        child: _AnimatedSetIndicator(
                          isCompleted: isCompleted,
                          setNumber: setIndex + 1,
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

// Анимированный индикатор подхода
class _AnimatedSetIndicator extends StatefulWidget {
  final bool isCompleted;
  final int setNumber;

  const _AnimatedSetIndicator({
    required this.isCompleted,
    required this.setNumber,
  });

  @override
  State<_AnimatedSetIndicator> createState() => _AnimatedSetIndicatorState();
}

class _AnimatedSetIndicatorState extends State<_AnimatedSetIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    
    _colorAnimation = ColorTween(
      begin: Colors.grey.shade300,
      end: const Color(0xFF4CAF50),
    ).animate(_controller);
    
    if (widget.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_AnimatedSetIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted != oldWidget.isCompleted) {
      if (widget.isCompleted) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(right: 4),
          height: 8,
          decoration: BoxDecoration(
            color: _colorAnimation.value ?? Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
          transform: Matrix4.identity()..scale(_scaleAnimation.value),
          child: Center(
            child: Text(
              '${widget.setNumber}',
              style: TextStyle(
                color: widget.isCompleted ? Colors.white : Colors.grey.shade600,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}