// lib/features/planner/utils/exercise_icon_utils.dart
import 'package:flutter/material.dart';

class ExerciseIconUtils {
  /// Возвращает цвет для группы мышц
  static Color getMuscleGroupColor(String muscleGroup) {
    final group = muscleGroup.toLowerCase();
    
    if (group.contains('chest') || group.contains('груд')) {
      return Colors.red[400]!;
    } else if (group.contains('back') || group.contains('спин')) {
      return Colors.green[400]!;
    } else if (group.contains('leg') || group.contains('ног')) {
      return Colors.blue[400]!;
    } else if (group.contains('shoulder') || group.contains('плеч')) {
      return Colors.orange[400]!;
    } else if (group.contains('arm') || group.contains('рук') || 
               group.contains('bicep') || group.contains('tricep')) {
      return Colors.purple[400]!;
    } else if (group.contains('core') || group.contains('пресс') || 
               group.contains('абд')) {
      return Colors.teal[400]!;
    } else if (group.contains('cardio') || group.contains('кардио')) {
      return Colors.cyan[400]!;
    } else {
      return Colors.grey[400]!;
    }
  }

  /// Возвращает иконку для упражнения
  static IconData getExerciseIcon(String exerciseId) {
    final id = exerciseId.toLowerCase();
    
    if (id.contains('pushup') || id.contains('отжимание')) {
      return Icons.self_improvement;
    } else if (id.contains('squat') || id.contains('присед')) {
      return Icons.directions_run;
    } else if (id.contains('pull') || id.contains('подтягивани')) {
      return Icons.trending_up; // Заменено с Icons.pull_request которого нет
    } else if (id.contains('plank') || id.contains('планк')) {
      return Icons.horizontal_rule;
    } else if (id.contains('curl') || id.contains('сгибание')) {
      return Icons.fitness_center;
    } else if (id.contains('crunch') || id.contains('скручивани')) {
      return Icons.rotate_90_degrees_ccw;
    } else if (id.contains('lunge') || id.contains('выпад')) {
      return Icons.directions_walk;
    } else if (id.contains('run') || id.contains('бег')) {
      return Icons.directions_run;
    } else if (id.contains('jump') || id.contains('прыж')) {
      return Icons.arrow_upward;
    } else if (id.contains('bench') || id.contains('скамья')) {
      return Icons.airline_seat_flat;
    } else if (id.contains('deadlift') || id.contains('становая')) {
      return Icons.unfold_more;
    } else if (id.contains('press') || id.contains('жим')) {
      return Icons.vertical_align_top;
    } else if (id.contains('row') || id.contains('тяга')) {
      return Icons.downhill_skiing;
    } else if (id.contains('raise') || id.contains('подъем')) {
      return Icons.arrow_upward;
    } else if (id.contains('extension') || id.contains('разгибани')) {
      return Icons.open_in_full;
    } else if (id.contains('fly') || id.contains('развод')) {
      return Icons.open_with;
    }
    
    return Icons.fitness_center;
  }

  /// Возвращает название группы мышц на русском
  static String getMuscleGroupName(String muscleGroup) {
    final group = muscleGroup.toLowerCase();
    
    if (group.contains('chest') || group.contains('груд')) {
      return 'Грудь';
    } else if (group.contains('back') || group.contains('спин')) {
      return 'Спина';
    } else if (group.contains('leg') || group.contains('ног')) {
      return 'Ноги';
    } else if (group.contains('shoulder') || group.contains('плеч')) {
      return 'Плечи';
    } else if (group.contains('arm') || group.contains('рук') || 
               group.contains('bicep') || group.contains('tricep')) {
      return 'Руки';
    } else if (group.contains('core') || group.contains('пресс') || 
               group.contains('абд')) {
      return 'Пресс';
    } else if (group.contains('cardio') || group.contains('кардио')) {
      return 'Кардио';
    } else {
      return 'Другое';
    }
  }

  /// Возвращает градиент для фона
  static List<Color> getMuscleGroupGradient(String muscleGroup) {
    final baseColor = getMuscleGroupColor(muscleGroup);
    return [
      baseColor.withAlpha(38), // 0.15 * 255 ≈ 38
      baseColor.withAlpha(20), // 0.08 * 255 ≈ 20
      baseColor.withAlpha(8),  // 0.03 * 255 ≈ 8
    ];
  }
}