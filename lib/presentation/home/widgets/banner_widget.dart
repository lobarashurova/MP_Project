import 'package:flutter/material.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/localization/app_strings.dart';
import 'package:xurmo/core/constants/app_pricing.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/data/models/meal_model.dart';

class BannerWidget extends StatelessWidget {
  /// A meal from the menu, or null while the menu is loading.
  final MealModel? meal;

  /// Called when the user taps "Order Now".
  final VoidCallback? onOrderNow;

  const BannerWidget({super.key, this.meal, this.onOrderNow});

  @override
  Widget build(BuildContext context) {
    final meal = this.meal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
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
                    color: Colors.white.withValues(alpha: 0.1),
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
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              if (meal != null && meal.imageUrl.isNotEmpty)
                Positioned(
                  right: 20,
                  top: 45,
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
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 190),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    meal != null ? 130 : 24,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(context.tr('todays_special'), style: AppTextStyles.bannerTitle),
                      const SizedBox(height: 8),
                      Text(
                        context
                            .tr('get_off')
                            .replaceFirst('{p}', '${AppPricing.promoDiscountPercent}'),
                        style: AppTextStyles.bannerSubtitle.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                      if (meal != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${context.tr('try_label')} ${meal.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: onOrderNow,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.onPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            context.tr('order_now'),
                            style: AppTextStyles.buttonPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
