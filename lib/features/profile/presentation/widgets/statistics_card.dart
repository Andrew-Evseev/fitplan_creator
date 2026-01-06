// lib/features/profile/presentation/widgets/statistics_card.dart
import 'package:flutter/material.dart';
import '../../models/user_profile.dart';

class StatisticsCard extends StatelessWidget {
  final UserProfile userProfile;

  const StatisticsCard({
    super.key,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Статистика',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Всего: ${userProfile.stats.totalWorkouts} тренировок',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (userProfile.stats.muscleGroupDistribution.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Распределение по группам мышц:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildMuscleGroupDistribution(),
                ],
              )
            else
              const Center(
                child: Text(
                  'Нет данных о тренировках',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildDetailStat(
                  'Среднее время',
                  '${userProfile.stats.averageWorkoutTime.toStringAsFixed(1)} мин',
                  Icons.timer_outlined,
                ),
                _buildDetailStat(
                  'Максимальный стрик',
                  '${userProfile.stats.maxStreak} дней',
                  Icons.star_border,
                ),
                _buildDetailStat(
                  'Всего упражнений',
                  '${userProfile.stats.totalExercises}',
                  Icons.format_list_numbered,
                ),
                _buildDetailStat(
                  'Топ группа',
                  _getTopMuscleGroupName(),
                  Icons.fitness_center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMuscleGroupDistribution() {
    final entries = userProfile.stats.muscleGroupDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final total = entries.fold(0, (sum, entry) => sum + entry.value);
    
    return entries.map((entry) {
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getMuscleGroupDisplayName(entry.key),
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: entry.value / total,
              backgroundColor: Colors.grey[200],
              color: _getMuscleGroupColor(entry.key),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDetailStat(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTopMuscleGroupName() {
    if (userProfile.stats.muscleGroupDistribution.isEmpty) {
      return 'Нет данных';
    }
    final sorted = userProfile.stats.muscleGroupDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _getMuscleGroupDisplayName(sorted.first.key);
  }

  String _getMuscleGroupDisplayName(String key) {
    switch (key.toLowerCase()) {
      case 'chest':
        return 'Грудь';
      case 'back':
        return 'Спина';
      case 'legs':
      case 'leg':
        return 'Ноги';
      case 'shoulders':
        return 'Плечи';
      case 'arms':
        return 'Руки';
      case 'core':
        return 'Пресс';
      case 'cardio':
        return 'Кардио';
      default:
        return key;
    }
  }

  Color _getMuscleGroupColor(String muscleGroup) {
    final group = muscleGroup.toLowerCase();
    if (group.contains('chest') || group.contains('груд')) {
      return Colors.red[400]!;
    } else if (group.contains('back') || group.contains('спин')) {
      return Colors.green[400]!;
    } else if (group.contains('leg') || group.contains('ног')) {
      return Colors.blue[400]!;
    } else if (group.contains('shoulder') || group.contains('плеч')) {
      return Colors.orange[400]!;
    } else if (group.contains('arm') || group.contains('рук')) {
      return Colors.purple[400]!;
    } else if (group.contains('core') || group.contains('пресс')) {
      return Colors.teal[400]!;
    } else if (group.contains('cardio') || group.contains('кардио')) {
      return Colors.cyan[400]!;
    } else {
      return Colors.grey[400]!;
    }
  }
}