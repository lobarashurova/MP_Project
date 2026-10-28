import 'package:flutter/material.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/app_pricing.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/data/repositories/meal_repository.dart';

class BannerWidget extends StatefulWidget {
  const BannerWidget({super.key});

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> {
  MealModel? _meal;

  @override
  void initState() {
    super.initState();
    _loadMeal();
  }

  Future<void> _loadMeal() async {
    try {
      final meal = await MealRepository().fetchRandomMeal();
      if (!mounted) return;
      setState(() => _meal = meal);
    } catch (_) {
      // The banner still works without a featured meal.
    }
  }

  @override
  Widget build(BuildContext context) {
    final meal = _meal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              if (meal != null && meal.imageUrl.isNotEmpty)
                Positioned(
                  right: 20,
                  top: 35,
                  child: ClipOval(
                    child: Image.network(
                      meal.imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 24, meal != null ? 130 : 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Today\'s Special',
                      style: AppTextStyles.bannerTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get ${AppPricing.promoDiscountPercent}% off on all dishes',
                      style: AppTextStyles.bannerSubtitle.copyWith(
                        color: AppColors.surface.withOpacity(0.9),
                      ),
                    ),
                    if (meal != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Try: ${meal.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Order Now',
                        style: AppTextStyles.buttonPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}