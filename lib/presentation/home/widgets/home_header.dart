import 'package:flutter/material.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, User',
            style: AppTextStyles.heading1,
          ),
          const SizedBox(height: 4),
          Text(
            'What would you like to eat today?',
            style: AppTextStyles.subtitle,
          ),
        ],
      ),
    );
  }
}
