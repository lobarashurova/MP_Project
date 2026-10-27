import 'package:flutter/material.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/presentation/home/widgets/meal_card.dart';
import 'package:xurmo/presentation/home/widgets/meal_card_shimmer.dart';

class MealsGrid extends StatelessWidget {
  final List<MealModel> meals;
  final bool isLoading;

  const MealsGrid({
    super.key,
    required this.meals,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: const [
            Expanded(child: MealCardShimmer()),
            SizedBox(width: 16),
            Expanded(child: MealCardShimmer()),
          ],
        ),
      );
    }

    if (meals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: MealCard(meal: meals[0]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: meals.length > 1
                ? MealCard(meal: meals[1])
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}
