// lib/app/router.dart
import 'package:flutter/material.dart'; // Добавляем этот импорт
import 'package:go_router/go_router.dart';
import 'package:fitplan_creator/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:fitplan_creator/features/onboarding/presentation/screens/loading_screen.dart';
import 'package:fitplan_creator/features/planner/presentation/screens/planner_screen.dart';
import 'package:fitplan_creator/features/profile/presentation/screens/profile_screen.dart';
// Импорт новой расширенной анкеты
import 'package:fitplan_creator/features/questionnaire/screens/extended_questionnaire_screen.dart';
// Также можно оставить старую анкету для отката, если нужно
import 'package:fitplan_creator/features/questionnaire/screens/questionnaire_screen.dart';

final router = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/questionnaire',
      name: 'questionnaire',
      // ИЗМЕНЕНИЕ: Используем расширенную анкету вместо обычной
      builder: (context, state) => const ExtendedQuestionnaireScreen(),
    ),
    // Можно добавить отдельный маршрут для старой анкеты, если нужно
    GoRoute(
      path: '/questionnaire-old',
      name: 'questionnaire-old',
      builder: (context, state) => const QuestionnaireScreen(),
    ),
    GoRoute(
      path: '/loading',
      name: 'loading',
      builder: (context, state) => const LoadingScreen(),
    ),
    GoRoute(
      path: '/planner',
      name: 'planner',
      builder: (context, state) => const PlannerScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
  // Редирект с корня на welcome
  redirect: (context, state) {
    if (state.matchedLocation == '/') {
      return '/welcome';
    }
    return null;
  },
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Страница не найдена',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            'Путь: ${state.matchedLocation}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => context.go('/welcome'),
            child: const Text('Вернуться на главную'),
          ),
        ],
      ),
    ),
  ),
);