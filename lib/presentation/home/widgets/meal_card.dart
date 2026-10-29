import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/core/theme/app_theme.dart';
import 'package:xurmo/core/widgets/quantity_stepper.dart';
import 'package:xurmo/core/utils/haptics.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/presentation/basket/cart.dart';
import 'package:xurmo/presentation/home/product_detail_page.dart';
import 'package:xurmo/presentation/favorites/provider/favorites_provider.dart';
import 'package:xurmo/core/utils/money.dart';
import 'package:xurmo/core/translation/translated_text.dart';

class MealCard extends StatefulWidget {
  final MealModel meal;

  const MealCard({
    super.key,
    required this.meal,
  });

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  late MealModel _product;
  int _quantity = 0;

  @override
  void initState() {
    super.initState();
    _product = widget.meal;
    _updateQuantity();
    Cart.instance.notifier.addListener(_updateQuantity);
  }
  @override
  void didUpdateWidget(covariant MealCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meal.id != widget.meal.id) {
      _product = widget.meal;
    }
  }

  @override
  void dispose() {
    Cart.instance.notifier.removeListener(_updateQuantity);
    super.dispose();
  }

  void _updateQuantity() {
    try {
      final cartItem = Cart.instance.items.firstWhere(
            (item) => item.product.id == _product.id,
      );
      if (mounted) {
        setState(() {
          _quantity = cartItem.quantity;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _quantity = 0;
        });
      }
    }
  }

  void _addToCart() {
    Haptics.success();
    Cart.instance.add(_product);
  }

  void _increaseQuantity() {
    Haptics.change();
    Cart.instance.increaseQuantity(_product);
  }

  void _decreaseQuantity() {
    Haptics.change();
    Cart.instance.decreaseQuantity(_product);
  }

  Future<void> _toggleFavorite(FavoritesProvider favProvider) async {
    // Favorites are stored per user, so a signed-out tap is a no-op rather
    // than an error. The heart simply stays unfilled.
    if (FirebaseAuth.instance.currentUser == null) return;

    final isFavorite = favProvider.isFavorite(_product.id);
    // The heart reflects provider state, so it reverts by itself if the write
    // fails; the tap haptic is the only feedback either way.
    Haptics.tap();

    try {
      if (isFavorite) {
        await favProvider.removeFavorite(_product.id);
      } else {
        await favProvider.addFavorite(_product);
      }
    } catch (e) {
      debugPrint('Failed to update favorites: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favProvider, _) {
        final isFavorite = favProvider.isFavorite(_product.id);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(meal: widget.meal),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusLarge),
                      ),
                      child: Image.network(
                        widget.meal.imageUrl,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 140,
                            color: AppColors.shadow,
                            child: Icon(
                              CupertinoIcons.photo,
                              color: AppColors.iconSecondary,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _toggleFavorite(favProvider),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Icon(
                            isFavorite
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            color: isFavorite
                                ? Colors.red
                                : AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        widget.meal.name,
                        style: AppTextStyles.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TranslatedText(
                              widget.meal.category,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TranslatedText(
                              widget.meal.area,
                              style: AppTextStyles.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.list_bullet,
                            color: AppColors.iconSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.meal.ingredients.length} ingredients',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // The price has to flex: with the currency suffix
                          // it is wide enough to push the stepper off a
                          // two-column card otherwise.
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatSum(_product.price),
                                style: AppTextStyles.productPrice,
                                maxLines: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (_quantity == 0)
                            GestureDetector(
                              onTap: _addToCart,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall,
                                  ),
                                ),
                                child: const Icon(
                                  CupertinoIcons.add,
                                  size: 18,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            )
                          else
                            QuantityStepper(
                              quantity: _quantity,
                              compact: true,
                              onDecrease: _decreaseQuantity,
                              onIncrease: _increaseQuantity,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}