// lib/features/planner/presentation/widgets/muscle_groups_visualization.dart
import 'package:flutter/material.dart';

class MuscleGroupsVisualization extends StatelessWidget {
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;

  const MuscleGroupsVisualization({
    super.key,
    required this.primaryMuscles,
    this.secondaryMuscles = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (primaryMuscles.isEmpty && secondaryMuscles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Задействованные мышцы:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Основные группы мышц
            ...primaryMuscles.map((muscle) => _buildMuscleChip(
              muscle,
              isPrimary: true,
            )),
            // Вторичные группы мышц
            ...secondaryMuscles.map((muscle) => _buildMuscleChip(
              muscle,
              isPrimary: false,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildMuscleChip(String muscle, {required bool isPrimary}) {
    final color = _getMuscleColor(muscle);
    final icon = _getMuscleIcon(muscle);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? color.withOpacity(0.2) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary ? color : Colors.grey[300]!,
          width: isPrimary ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isPrimary ? color : Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Text(
            muscle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
              color: isPrimary ? color : Colors.grey[700],
            ),
          ),
          if (isPrimary) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getMuscleColor(String muscle) {
    final muscleLower = muscle.toLowerCase();
    
    if (muscleLower.contains('груд') || muscleLower.contains('chest')) {
      return Colors.red;
    } else if (muscleLower.contains('спин') || muscleLower.contains('back')) {
      return Colors.green;
    } else if (muscleLower.contains('ног') || muscleLower.contains('leg')) {
      return Colors.blue;
    } else if (muscleLower.contains('плеч') || muscleLower.contains('shoulder')) {
      return Colors.orange;
    } else if (muscleLower.contains('рук') || muscleLower.contains('arm') || 
               muscleLower.contains('бицепс') || muscleLower.contains('трицепс')) {
      return Colors.purple;
    } else if (muscleLower.contains('пресс') || muscleLower.contains('core') || 
               muscleLower.contains('абд')) {
      return Colors.teal;
    } else if (muscleLower.contains('кардио') || muscleLower.contains('cardio')) {
      return Colors.cyan;
    } else {
      return Colors.grey;
    }
  }

  IconData _getMuscleIcon(String muscle) {
    final muscleLower = muscle.toLowerCase();
    
    if (muscleLower.contains('груд') || muscleLower.contains('chest')) {
      return Icons.fitness_center;
    } else if (muscleLower.contains('спин') || muscleLower.contains('back')) {
      return Icons.accessibility_new;
    } else if (muscleLower.contains('ног') || muscleLower.contains('leg')) {
      return Icons.directions_run;
    } else if (muscleLower.contains('плеч') || muscleLower.contains('shoulder')) {
      return Icons.arrow_upward;
    } else if (muscleLower.contains('рук') || muscleLower.contains('arm')) {
      return Icons.pan_tool;
    } else if (muscleLower.contains('пресс') || muscleLower.contains('core')) {
      return Icons.crop_square;
    } else if (muscleLower.contains('кардио') || muscleLower.contains('cardio')) {
      return Icons.favorite;
    } else {
      return Icons.fitness_center;
    }
  }
}
