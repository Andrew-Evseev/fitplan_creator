// lib/features/profile/presentation/widgets/achievement_badge.dart
import 'package:flutter/material.dart';

class AchievementBadge extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
  final DateTime? unlockedAt;

  const AchievementBadge({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.unlocked = false,
    this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked ? Colors.amber[50]! : Colors.grey[100]!,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? Colors.amber : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: unlocked ? Colors.amber : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: unlocked ? Colors.black : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: unlocked ? Colors.black54 : Colors.grey,
                  ),
                ),
                if (unlocked && unlockedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Получено: ${_formatDate(unlockedAt!)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            unlocked ? Icons.lock_open : Icons.lock,
            color: unlocked ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}