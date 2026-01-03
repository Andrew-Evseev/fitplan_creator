import 'package:flutter/material.dart';
import 'package:fitplan_creator/core/constants/app_colors.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  
  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: AppColors.textColor.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}