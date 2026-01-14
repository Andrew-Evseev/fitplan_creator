// lib/features/planner/presentation/widgets/training_system_info_card.dart
import 'package:flutter/material.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'package:fitplan_creator/data/models/workout_plan.dart';

class TrainingSystemInfoCard extends StatelessWidget {
  final TrainingSystem? system;
  final String? systemName;
  final String? description;
  final Map<String, String>? progressionTips;
  final WorkoutPlan? plan; // Добавляем план для получения объяснения

  const TrainingSystemInfoCard({
    super.key,
    this.system,
    this.systemName,
    this.description,
    this.progressionTips,
    this.plan,
  });

  @override
  Widget build(BuildContext context) {
    if (system == null && systemName == null) {
      return const SizedBox.shrink();
    }

    final displayName = system?.displayName ?? systemName ?? 'Система тренировок';
    final displayDescription = system?.description ?? description ?? '';
    final icon = _getSystemIcon(system);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showSystemDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getSystemColor(system).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: _getSystemColor(system),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (displayDescription.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            displayDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
              // Объяснение выбора системы
              if (plan?.metadata != null && plan!.metadata!['systemSelectionReason'] != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Container(
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
                          Icon(
                            Icons.lightbulb_outline,
                            size: 18,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Почему выбрана эта система:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        plan!.metadata!['systemSelectionReason'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[900],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (progressionTips != null && progressionTips!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Рекомендации по прогрессии:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                ...progressionTips!.entries.take(2).map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: _getSystemColor(system),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSystemIcon(TrainingSystem? system) {
    switch (system) {
      case TrainingSystem.fullBody:
        return Icons.fitness_center;
      case TrainingSystem.split:
        return Icons.view_module;
      case TrainingSystem.ppl:
        return Icons.repeat;
      case TrainingSystem.upperLower:
        return Icons.swap_vert;
      case TrainingSystem.circuit:
        return Icons.autorenew;
      case TrainingSystem.cardio:
        return Icons.directions_run;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getSystemColor(TrainingSystem? system) {
    switch (system) {
      case TrainingSystem.fullBody:
        return const Color(0xFF2196F3);
      case TrainingSystem.split:
        return const Color(0xFF9C27B0);
      case TrainingSystem.ppl:
        return const Color(0xFFFF9800);
      case TrainingSystem.upperLower:
        return const Color(0xFF4CAF50);
      case TrainingSystem.circuit:
        return const Color(0xFFF44336);
      case TrainingSystem.cardio:
        return const Color(0xFF00BCD4);
      default:
        return const Color(0xFF2196F3);
    }
  }

  void _showSystemDetails(BuildContext context) {
    final displayName = system?.displayName ?? systemName ?? 'Система тренировок';
    final displayDescription = system?.description ?? description ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getSystemColor(system).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getSystemIcon(system),
                      color: _getSystemColor(system),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (system != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            system?.audience ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (displayDescription.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  displayDescription,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
              // Детальное объяснение выбора системы
              if (plan != null && plan!.metadata != null && plan!.metadata!['explanation'] != null)
                Builder(
                  builder: (context) {
                    final planData = plan!;
                    final explanation = planData.metadata!['explanation'] as Map<String, dynamic>?;
                    if (explanation == null) return const SizedBox.shrink();
                    
                    Widget buildSection(String title, String text, IconData icon) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, size: 18, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            text,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                              height: 1.4,
                            ),
                          ),
                        ],
                      );
                    }
                    
                    return Column(
                      children: [
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb,
                                    color: Colors.blue[700],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Почему выбран этот план:',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (explanation['systemReason'] != null) ...[
                                buildSection(
                                  'Выбор системы тренировок',
                                  explanation['systemReason'] as String,
                                  Icons.fitness_center,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (explanation['parametersReason'] != null) ...[
                                buildSection(
                                  'Параметры тренировок',
                                  explanation['parametersReason'] as String,
                                  Icons.tune,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (explanation['exerciseSelectionReason'] != null) ...[
                                buildSection(
                                  'Подбор упражнений',
                                  explanation['exerciseSelectionReason'] as String,
                                  Icons.list,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
            if (progressionTips != null && progressionTips!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Рекомендации по прогрессии:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...progressionTips!.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: _getSystemColor(system),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть'),
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }

}
