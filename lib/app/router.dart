import 'package:go_router/go_router.dart';
import 'package:fitplan_creator/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:fitplan_creator/features/onboarding/presentation/screens/loading_screen.dart';
import 'package:fitplan_creator/features/planner/presentation/screens/planner_screen.dart';
import 'package:fitplan_creator/features/questionnaire/screens/questionnaire_screen.dart';

final router = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/questionnaire',
      builder: (context, state) => const QuestionnaireScreen(),
    ),
    GoRoute(
      path: '/loading',
      builder: (context, state) => const LoadingScreen(),
    ),
    GoRoute(
      path: '/planner',
      builder: (context, state) => const PlannerScreen(),
    ),
  ],
);