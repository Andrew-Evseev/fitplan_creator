import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitplan_creator/core/constants/app_colors.dart';
import 'package:fitplan_creator/core/widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Логотип
              const Icon(
                Icons.fitness_center,
                size: 100,
                color: AppColors.primaryColor,
              ),
              const SizedBox(height: 30),
              
              // Заголовок
              const Text(
                'FitPlan Creator',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              
              // Подзаголовок
              const Text(
                'Персональный план тренировок\nза 5 минут',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF666666), // Исправлено: вместо withOpacity(0.8)
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              
              // Описание
              const Text(
                'Создайте идеальную программу тренировок,\nоснованную на ваших целях и оборудовании',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF888888), // Исправлено: вместо withOpacity(0.6)
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              
              // Кнопка начать
              CustomButton(
                text: 'Начать',
                onPressed: () {
                  context.push('/questionnaire');
                },
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}