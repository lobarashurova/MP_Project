import 'package:flutter/material.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/core/theme/app_theme.dart';
import 'package:xurmo/core/utils/haptics.dart';

class CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ScrollController scrollController;
  final Function(String) onCategoryTap;

  const CategoryBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.scrollController,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = selectedCategory == category;

            return GestureDetector(
              onTap: () {
                Haptics.selection();
                onCategoryTap(category);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                margin: const EdgeInsets.only(right: AppTheme.spaceSm + 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMd + 2,
                  vertical: AppTheme.spaceSm + 4,
                ),
                decoration: BoxDecoration(
                  // Unselected chips sit on the alt surface with no shadow:
                  // only the selected one is raised, so the row has a single
                  // focal point instead of a wall of floating cards.
                  color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  boxShadow: isSelected ? AppTheme.cardShadow : null,
                ),
                child: Center(
                  child: Text(
                    category,
                    style: AppTextStyles.categoryChip.copyWith(
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
