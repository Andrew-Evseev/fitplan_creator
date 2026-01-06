import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/statistics_card.dart';
import '../widgets/plan_history_card.dart';
import '../widgets/settings_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              context.go('/planner');
            },
            tooltip: 'Вернуться к плану',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ProfileHeader(
                userProfile: userProfile,
                onEditPressed: () {
                  _showEditProfileDialog(context, ref);
                },
              ),
            ),
            
            StatisticsCard(userProfile: userProfile),
            
            PlanHistoryCard(workoutHistory: userProfile.workoutHistory),
            
            const SettingsCard(),  // Убрал параметр settings
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.history),
                      label: const Text('Сбросить статистику'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        _showResetStatsDialog(context, ref);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Поделиться прогрессом'),
                      onPressed: () {
                        // TODO: Поделиться прогрессом
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final profile = ref.read(profileProvider);
    final nameController = TextEditingController(text: profile.name);
    final emailController = TextEditingController(text: profile.email);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Редактировать профиль'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(profileProvider.notifier).updateProfile(
                  name: nameController.text,
                  email: emailController.text.isNotEmpty
                      ? emailController.text
                      : null,
                );
                Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  void _showResetStatsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Сбросить статистику'),
          content: const Text(
            'Вы уверены, что хотите сбросить всю статистику? '
            'Это действие нельзя отменить.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(profileProvider.notifier).resetStats();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Статистика сброшена'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Сбросить'),
            ),
          ],
        );
      },
    );
  }
}