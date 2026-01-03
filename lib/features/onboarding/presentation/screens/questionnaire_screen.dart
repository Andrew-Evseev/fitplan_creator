import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitplan_creator/core/constants/app_colors.dart';
import 'package:fitplan_creator/core/widgets/custom_button.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Анкета'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Экран анкеты'),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Далее',
              onPressed: () {
                context.push('/loading');
              },
            ),
          ],
        ),
      ),
    );
  }
}