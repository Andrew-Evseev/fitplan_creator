import 'package:flutter/material.dart';
import '../../models/user_profile.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile userProfile;
  final VoidCallback? onEditPressed;

  const ProfileHeader({
    super.key,
    required this.userProfile,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage: userProfile.avatarUrl != null
                        ? NetworkImage(userProfile.avatarUrl!)
                        : null,
                    child: userProfile.avatarUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                  if (onEditPressed != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: onEditPressed,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProfile.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (userProfile.email != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          userProfile.email!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Участник с ${_formatDate(userProfile.joinDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                value: userProfile.stats.totalWorkouts.toString(),
                label: 'Тренировок',
                icon: Icons.fitness_center,
              ),
              _buildStatItem(
                value: '${userProfile.stats.totalMinutes}',
                label: 'Минут',
                icon: Icons.timer,
              ),
              _buildStatItem(
                value: '${userProfile.stats.currentStreak}',
                label: 'Дней стрик',
                icon: Icons.local_fire_department,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}