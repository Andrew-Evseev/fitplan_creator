// lib/features/profile/presentation/widgets/saved_plans_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/profile_provider.dart';
import '../../models/user_profile.dart';
import 'package:fitplan_creator/features/planner/providers/planner_provider.dart';

class SavedPlansCard extends ConsumerWidget {
  final List<SavedPlan> savedPlans;

  const SavedPlansCard({
    super.key,
    required this.savedPlans,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bookmark, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Сохраненные планы',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Всего: ${savedPlans.length}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (savedPlans.isNotEmpty)
              ...savedPlans.map((plan) => _buildPlanItem(context, ref, plan))
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Нет сохраненных планов',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanItem(BuildContext context, WidgetRef ref, SavedPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (plan.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        plan.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red,
                onPressed: () {
                  _showDeleteDialog(context, ref, plan);
                },
                tooltip: 'Удалить план',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (plan.trainingSystem != null) ...[
                Chip(
                  label: Text(
                    plan.trainingSystem!,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.blue[100],
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.fitness_center,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${plan.workoutsCount} тренировок',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(plan.savedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Загрузить план'),
              onPressed: () {
                _loadPlan(context, ref, plan);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _loadPlan(BuildContext context, WidgetRef ref, SavedPlan savedPlan) {
    final plan = ref.read(profileProvider.notifier).loadSavedPlan(savedPlan.planId);
    if (plan != null) {
      ref.read(plannerProvider.notifier).loadPlan(plan);
      context.go('/planner');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('План "${plan.name}" загружен'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при загрузке плана'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, SavedPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить план?'),
        content: Text('Вы уверены, что хотите удалить план "${plan.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(profileProvider.notifier).deleteSavedPlan(plan.planId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('План удален'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final planDay = DateTime(date.year, date.month, date.day);

    if (planDay == today) {
      return 'Сохранено сегодня';
    } else if (planDay == yesterday) {
      return 'Сохранено вчера';
    } else {
      return 'Сохранено ${date.day}.${date.month}.${date.year}';
    }
  }
}
