import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitplan_creator/core/constants/app_colors.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Имитация загрузки
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.pushReplacement('/planner');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 30),
            Text(
              'Подбираем оптимальную программу...',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textColor.withAlpha(200), // Исправлено
              ),
            ),
          ],
        ),
      ),
    );
  }
}