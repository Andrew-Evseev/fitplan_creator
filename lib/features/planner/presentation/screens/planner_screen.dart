import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitplan_creator/core/constants/app_colors.dart';
import 'package:fitplan_creator/core/widgets/custom_button.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Конструктор плана'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Экран конструктора плана'),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Начать заново',
              onPressed: () {
                context.go('/welcome');
              },
            ),
          ],
        ),
      ),
    );
  }
}