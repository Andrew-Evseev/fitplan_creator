// lib/features/profile/presentation/widgets/plan_history_card.dart
import 'package:flutter/material.dart';
import '../../models/user_profile.dart';

class PlanHistoryCard extends StatelessWidget {
  final List<WorkoutHistory> workoutHistory;

  const PlanHistoryCard({
    super.key,
    required this.workoutHistory,
  });

  @override
  Widget build(BuildContext context) {
    final recentHistory = workoutHistory.take(5).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'История тренировок',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Всего: ${workoutHistory.length}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentHistory.isNotEmpty)
              ...recentHistory.map((history) => _buildHistoryItem(history))
            else
              const Center(
                child: Text(
                  'Нет истории тренировок',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            if (workoutHistory.length > 5)
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Показать полную историю
                  },
                  child: const Text('Показать все тренировки'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(WorkoutHistory history) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: history.completed ? Colors.green[100]! : Colors.orange[100]!,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: history.completed ? Colors.green : Colors.orange,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: history.completed ? Colors.green[100]! : Colors.orange[100]!,
              shape: BoxShape.circle,
            ),
            child: Icon(
              history.completed ? Icons.check : Icons.timer,
              color: history.completed ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.planName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(history.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.timer,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${history.duration} мин',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Chip(
            label: Text('${history.exercisesCount} упр.'),
            backgroundColor: Colors.blue[50],
            labelStyle: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final workoutDay = DateTime(date.year, date.month, date.day);

    if (workoutDay == today) {
      return 'Сегодня';
    } else if (workoutDay == yesterday) {
      return 'Вчера';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}